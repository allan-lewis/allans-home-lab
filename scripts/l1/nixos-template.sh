#!/usr/bin/env bash
set -euo pipefail

###
# nixos-template.sh
#
# Builds a NixOS qcow2 from infra/os/nixos (flake output: proxmox-base-qcow2),
# uploads it to Proxmox, imports it as a VM disk, and converts the VM to a template.
#
# Requirements (env vars):
#   PVE_ACCESS_HOST   e.g. https://maturin.hosts.allanshomelab.com
#   PVE_NODE          e.g. maturin
#   PVE_STORAGE_VM    e.g. local-lvm
#   PVE_SSH_USER      e.g. gitops or root (must be able to run qm)
#   PVE_SSH_IP        e.g. 10.0.0.10 (direct IP, not reverse proxy)
#
# Optional env:
#   NIXOS_TEMPLATE_VMID    (if unset, we call pvesh get /cluster/nextid)
#   NIXOS_TEMPLATE_NAME    (default: nixos-YYYYMMDD)
#   UPDATE_STABLE          (default: yes)
#   NIXOS_MEM_MB           (default: 2048)
#   NIXOS_CORES            (default: 2)
#   NIXOS_BRIDGE           (default: vmbr0)
#   NIXOS_TAGS             (default: orchestrator,template,nixos)
#   NIXOS_DISK_IMPORT_FMT  (default: qcow2)
#
# Notes:
# - All qm/pvesh commands run remotely on the Proxmox node over SSH.
# - The qcow2 build output is linked under repo-root/artifacts (gitignored) via --out-link.
###

: "${PVE_ACCESS_HOST:?Missing PVE_ACCESS_HOST}"
: "${PVE_NODE:?Missing PVE_NODE}"
: "${PVE_STORAGE_VM:?Missing PVE_STORAGE_VM}"
: "${PVE_SSH_USER:?Missing PVE_SSH_USER}"
: "${PVE_SSH_IP:?Missing PVE_SSH_IP}"

UPDATE_STABLE="${UPDATE_STABLE:-yes}"
NIXOS_TEMPLATE_NAME="${NIXOS_TEMPLATE_NAME:-nixos-$(date -u +"%Y%m%d")}"

NIXOS_MEM_MB="${NIXOS_MEM_MB:-2048}"
NIXOS_CORES="${NIXOS_CORES:-2}"
NIXOS_BRIDGE="${NIXOS_BRIDGE:-vmbr0}"
NIXOS_TAGS="${NIXOS_TAGS:-orchestrator,template,nixos}"
NIXOS_DISK_IMPORT_FMT="${NIXOS_DISK_IMPORT_FMT:-qcow2}"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# NixOS flake location (in-repo)
NIXOS_FLAKE_DIR="${REPO_ROOT}/infra/os/nixos"

# Keep build output symlink outside infra/ so it can't be committed accidentally
OUT_LINK_DIR="${REPO_ROOT}/artifacts/nixos"
OUT_LINK="${OUT_LINK_DIR}/proxmox-base-qcow2"

mkdir -p "${OUT_LINK_DIR}"

SSH_HOST="${PVE_SSH_IP#*://}"
SSH_HOST="${SSH_HOST%/}"

SSH_OPTS=(
  -o BatchMode=yes
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
)

echo "=== NixOS Proxmox template build ==="
echo "Flake dir       : ${NIXOS_FLAKE_DIR}"
echo "Out link        : ${OUT_LINK}"
echo "Template name   : ${NIXOS_TEMPLATE_NAME}"
echo "Proxmox node    : ${PVE_NODE}"
echo "Proxmox storage : ${PVE_STORAGE_VM}"
echo "Proxmox ssh     : ${PVE_SSH_USER}@${SSH_HOST}"
echo

if [[ ! -f "${NIXOS_FLAKE_DIR}/flake.nix" ]]; then
  echo "ERROR: flake.nix not found at ${NIXOS_FLAKE_DIR}" >&2
  exit 1
fi

echo "==> Building qcow2 via Nix flake..."
(
  cd "${NIXOS_FLAKE_DIR}"
  nix build .#proxmox-base-qcow2 --out-link "${OUT_LINK}"
)

if [[ ! -e "${OUT_LINK}" ]]; then
  echo "ERROR: expected out-link to exist at ${OUT_LINK}" >&2
  exit 1
fi

# Find the actual disk image produced. Commonly it's a .qcow2 file inside the out-link path.
echo "==> Locating built disk image..."
IMAGE_PATH="$(
  find -L "${OUT_LINK}" -maxdepth 2 -type f \( -name "*.qcow2" -o -name "*.qcow" -o -name "*.img" -o -name "*.raw" \) \
    -print0 | xargs -0 ls -1S 2>/dev/null | head -n 1
)"

if [[ -z "${IMAGE_PATH}" || ! -f "${IMAGE_PATH}" ]]; then
  echo "ERROR: could not find qcow2/img/raw inside ${OUT_LINK}" >&2
  echo "Contents:" >&2
  find -L "${OUT_LINK}" -maxdepth 3 -type f -print >&2 || true
  exit 1
fi

IMAGE_NAME="nixos-proxmox-base-$(date -u +"%Y%m%d-%H%M%S").qcow2"
LOCAL_IMAGE="${OUT_LINK_DIR}/${IMAGE_NAME}"

# Copy to a stable filename in artifacts/ so rsync has a predictable source
echo "==> Copying image to ${LOCAL_IMAGE}..."
cp -f "${IMAGE_PATH}" "${LOCAL_IMAGE}"

echo "==> Calculating SHA256 + size..."
SHA256="$(sha256sum "${LOCAL_IMAGE}" | awk '{print $1}')"
SIZE_BYTES="$(wc -c <"${LOCAL_IMAGE}" | tr -d ' ')"
echo "SHA256     : ${SHA256}"
echo "Size bytes : ${SIZE_BYTES}"

echo
echo "==> Uploading image to Proxmox (/tmp/${IMAGE_NAME})..."
rsync -ah --progress \
  -e "ssh ${SSH_OPTS[*]}" \
  "${LOCAL_IMAGE}" \
  "${PVE_SSH_USER}@${SSH_HOST}:/tmp/${IMAGE_NAME}"

echo
echo "==> Selecting VMID on Proxmox..."
if [[ -n "${NIXOS_TEMPLATE_VMID:-}" ]]; then
  VMID="${NIXOS_TEMPLATE_VMID}"
  echo "Using provided VMID: ${VMID}"
else
  VMID="$(
    ssh "${SSH_OPTS[@]}" "${PVE_SSH_USER}@${SSH_HOST}" \
      "pvesh get /cluster/nextid"
  )"
  echo "Using next available VMID from Proxmox: ${VMID}"
fi

echo
echo "==> Creating / refreshing Proxmox VM template (VMID=${VMID})..."
ssh "${SSH_OPTS[@]}" "${PVE_SSH_USER}@${SSH_HOST}" "bash -s" <<EOF
set -euo pipefail

VMID="${VMID}"
NAME="${NIXOS_TEMPLATE_NAME}"
STORAGE="${PVE_STORAGE_VM}"
IMAGE_PATH="/tmp/${IMAGE_NAME}"
TAGS="${NIXOS_TAGS}"
MEM="${NIXOS_MEM_MB}"
CORES="${NIXOS_CORES}"
BRIDGE="${NIXOS_BRIDGE}"
IMPORT_FMT="${NIXOS_DISK_IMPORT_FMT}"

if [ ! -f "\${IMAGE_PATH}" ]; then
  echo "ERROR: image not found at \${IMAGE_PATH}" >&2
  exit 1
fi

echo "Proxmox: checking for existing VMID \${VMID}..."
if qm status "\${VMID}" >/dev/null 2>&1; then
  echo "VMID \${VMID} already exists, destroying existing VM/template..."
  qm stop "\${VMID}" || true
  qm destroy "\${VMID}" --purge 1 || qm destroy "\${VMID}" || true
fi

echo "Creating VM \${VMID} (\${NAME})..."
qm create "\${VMID}" \
  --name "\${NAME}" \
  --memory "\${MEM}" \
  --cores "\${CORES}" \
  --net0 virtio,bridge="\${BRIDGE}" \
  --ostype l26 \
  --machine q35 \
  --tags "\${TAGS}" \
  --onboot 0

echo "Importing disk into storage \${STORAGE}..."
qm importdisk "\${VMID}" "\${IMAGE_PATH}" "\${STORAGE}" --format "\${IMPORT_FMT}"

echo "Attaching disk as scsi0 and configuring SCSI controller..."
qm set "\${VMID}" \
  --scsihw virtio-scsi-pci \
  --scsi0 "\${STORAGE}:vm-\${VMID}-disk-0"

echo "Attaching cloud-init drive (ide2)..."
qm set "\${VMID}" --ide2 "\${STORAGE}:cloudinit"

echo "Setting boot order to scsi0..."
qm set "\${VMID}" --boot order=scsi0

echo "Configuring serial console and VGA for headless usage..."
qm set "\${VMID}" --serial0 socket --vga serial0

echo "Enabling QEMU guest agent..."
qm set "\${VMID}" --agent 1

echo "Converting VM \${VMID} to template..."
qm template "\${VMID}"

echo "Cleaning up uploaded image..."
rm -f "\${IMAGE_PATH}"

echo "Template \${VMID} (\${NAME}) ready."
EOF

echo
echo "==> Generating manifest JSON..."

TIMESTAMP_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
ARTIFACT_DIR="${REPO_ROOT}/infra/os/nixos/artifacts"
SPEC_DIR="${REPO_ROOT}/infra/os/nixos/spec"
mkdir -p "${ARTIFACT_DIR}" "${SPEC_DIR}"

MANIFEST_FILE="${ARTIFACT_DIR}/vm-template-$(date -u +"%Y%m%d-%H%M%S").json"

# Git provenance (best effort)
GIT_COMMIT="$(git -C "${REPO_ROOT}" rev-parse HEAD 2>/dev/null || true)"
GIT_DIRTY="false"
if git -C "${REPO_ROOT}" diff --quiet 2>/dev/null; then :; else GIT_DIRTY="true"; fi
if git -C "${REPO_ROOT}" diff --cached --quiet 2>/dev/null; then :; else GIT_DIRTY="true"; fi

# nixpkgs locked rev (best effort, via python to avoid jq dependency)
NIXPKGS_LOCKED_REV="$(
  python3 - <<'PY' 2>/dev/null || true
import json, pathlib
p = pathlib.Path("infra/os/nixos/flake.lock")
if not p.exists():
    print("")
    raise SystemExit(0)
data = json.loads(p.read_text())
node = data.get("nodes", {}).get("nixpkgs", {})
locked = node.get("locked", {})
print(locked.get("rev",""))
PY
)"

cat >"${MANIFEST_FILE}" <<EOF
{
  "created_at": "${TIMESTAMP_UTC}",
  "description": "NixOS base qcow2 for Proxmox (ssh + qemu-guest-agent + cloud-init)",
  "name": "${NIXOS_TEMPLATE_NAME}",
  "node": "${PVE_NODE}",
  "storage": "${PVE_STORAGE_VM}",
  "vmid": ${VMID},

  "artifact": {
    "type": "qcow2",
    "filename": "$(basename "${LOCAL_IMAGE}")",
    "sha256": "${SHA256}",
    "size_bytes": ${SIZE_BYTES}
  },

  "source": {
    "flake_dir": "infra/os/nixos",
    "flake_output": ".#proxmox-base-qcow2",
    "git_commit": "${GIT_COMMIT}",
    "git_dirty": ${GIT_DIRTY},
    "nixpkgs_locked_rev": "${NIXPKGS_LOCKED_REV}"
  }
}
EOF

echo "Manifest written to: ${MANIFEST_FILE}"
cat "${MANIFEST_FILE}"

if [[ "${UPDATE_STABLE}" == "yes" ]]; then
  STABLE_PATH="${SPEC_DIR}/vm-template-stable.json"
  ln -sf "../artifacts/$(basename "${MANIFEST_FILE}")" "${STABLE_PATH}"
  echo
  echo "Stable manifest now points to: ${STABLE_PATH}"
  ls -l "${STABLE_PATH}"
fi

echo
echo "=== Done. ==="
