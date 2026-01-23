#!/usr/bin/env bash
set -euo pipefail

# restore-to-template.sh <os>
#
# Reads disk capture manifest:
#   infra/os/<os>/spec/disk-capture-stable.json
#
# Override manifest path (still relative to infra/os/<os>/):
#   CAPTURE_MANIFEST_REL="spec/disk-capture-20260120.json"
#
# Required tools: jq, aws, ssh, scp
#
# Optional env:
#   PROXMOX_USER         default: root
#   PROXMOX_SSH_OPTS     default: disables host key checking
#   STORAGE              default: local-lvm
#   TEMPLATE_CPU         default: 2
#   TEMPLATE_MEMORY_MB   default: 2048
#   TEMPLATE_BRIDGE      default: vmbr0
#   TEMPLATE_MODEL       default: virtio
#   TEMPLATE_SCSIHw      default: virtio-scsi-single
#   KEEP_LOCAL_QCOW2     default: 0 (set to 1 to keep local downloaded qcow2)
#   TMPDIR               default: /home/lab/restore-template
#   DESCRIPTION          overrides description in generated template manifest

OS="${1:?Usage: $0 <os>}"

need_cmd() { command -v "$1" >/dev/null 2>&1 || {
  echo "ERROR: missing required command: $1" >&2
  exit 1
}; }
need_cmd jq
need_cmd aws
need_cmd ssh
need_cmd scp

# Figure out repo root (prefer git to make script runnable from anywhere inside repo)
repo_root="$(
  if command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel
  else
    pwd
  fi
)"

os_root="${repo_root}/infra/os/${OS}"

PROXMOX_NODE="${PVE_SSH_IP}"
UPDATE_STABLE="${UPDATE_STABLE:-yes}"

# Allow override *under* infra/os/<os>/
CAPTURE_MANIFEST_REL="${CAPTURE_MANIFEST_REL:-spec/disk-capture-stable.json}"

# Enforce "below infra/os/<os>/" and prevent path traversal
if [[ "${CAPTURE_MANIFEST_REL}" = /* ]] || [[ "${CAPTURE_MANIFEST_REL}" == *".."* ]]; then
  echo "ERROR: CAPTURE_MANIFEST_REL must be a relative path under infra/os/${OS}/ (no leading /, no ..)" >&2
  exit 1
fi

capture_manifest="${os_root}/${CAPTURE_MANIFEST_REL}"

if [[ ! -f "${capture_manifest}" ]]; then
  echo "ERROR: capture manifest not found: ${capture_manifest}" >&2
  exit 1
fi

# Read required fields from capture manifest
created_at="$(jq -r '.created_at // empty' "${capture_manifest}")"
capture_description="$(jq -r '.description // empty' "${capture_manifest}")"
manifest_os="$(jq -r '.os // empty' "${capture_manifest}")"
capture_vmid="$(jq -r '.vmid // empty' "${capture_manifest}")"
s3_uri="$(jq -r '.s3_uri // empty' "${capture_manifest}")"

# Validate
err=0
[[ -n "${manifest_os}" ]] || {
  echo "ERROR: manifest missing .os" >&2
  err=1
}
[[ -n "${s3_uri}" ]] || {
  echo "ERROR: manifest missing .s3_uri" >&2
  err=1
}
[[ "${manifest_os}" = "${OS}" ]] || {
  echo "ERROR: manifest .os (${manifest_os}) does not match arg OS (${OS})" >&2
  err=1
}
[[ "${err}" -eq 0 ]] || exit 1

PROXMOX_USER="${PROXMOX_USER:-root}"
DEFAULT_SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PROXMOX_SSH_OPTS="${PROXMOX_SSH_OPTS:-$DEFAULT_SSH_OPTS}"

STORAGE="${STORAGE:-local-lvm}"

TEMPLATE_CPU="${TEMPLATE_CPU:-2}"
TEMPLATE_MEMORY_MB="${TEMPLATE_MEMORY_MB:-2048}"
TEMPLATE_BRIDGE="${TEMPLATE_BRIDGE:-vmbr0}"
TEMPLATE_MODEL="${TEMPLATE_MODEL:-virtio}"
TEMPLATE_SCSIHw="${TEMPLATE_SCSIHw:-virtio-scsi-single}"
KEEP_LOCAL_QCOW2="${KEEP_LOCAL_QCOW2:-0}"

REMOTE="${PROXMOX_USER}@${PROXMOX_NODE}"

timestamp_day() { date +"%Y%m%d"; }

echo "==> Restore-to-template (from disk capture manifest)"
echo "==> OS:                ${OS}"
echo "==> Capture manifest:   ${capture_manifest}"
echo "==> Capture created_at: ${created_at:-<unknown>}"
echo "==> Capture vmid:       ${capture_vmid:-<unknown>}"
echo "==> Proxmox node:       ${PROXMOX_NODE}"
echo "==> Storage:            ${STORAGE}"
echo "==> S3 URI:             ${s3_uri}"
echo "==> SSH opts:           ${PROXMOX_SSH_OPTS}"
echo

# 1) Determine local filename from s3_uri
BASE_NAME="$(basename "${s3_uri}")"
if [[ -z "${BASE_NAME}" ]] || [[ "${BASE_NAME}" = "/" ]]; then
  echo "ERROR: unable to derive filename from s3_uri: ${s3_uri}" >&2
  exit 1
fi

# 2) Download qcow2 locally (ops host)
LOCAL_TMP_DIR="${TMPDIR:-/home/lab/.appliances/template}"
mkdir -p "${LOCAL_TMP_DIR}"
LOCAL_QCOW2="${LOCAL_TMP_DIR}/${BASE_NAME}"

if [[ -f "${LOCAL_QCOW2}" ]]; then
  echo "==> Local QCOW2 already exists, skipping download: ${LOCAL_QCOW2}"
else
  echo "==> Downloading to local temp: ${LOCAL_QCOW2}"
  aws s3 cp --only-show-errors "${s3_uri}" "${LOCAL_QCOW2}"
fi

# 3) Copy qcow2 to Proxmox node
REMOTE_TMP="/var/tmp/${BASE_NAME}"
echo "==> Copying QCOW2 to Proxmox: ${REMOTE_TMP}"
scp ${PROXMOX_SSH_OPTS} "${LOCAL_QCOW2}" "${REMOTE}:${REMOTE_TMP}"

# 4) Allocate a new VMID on Proxmox
echo "==> Allocating new VMID on Proxmox..."
VMID="$(
  ssh ${PROXMOX_SSH_OPTS} "${REMOTE}" "set -euo pipefail; pvesh get /cluster/nextid"
)"
if [[ -z "${VMID}" ]]; then
  echo "ERROR: Failed to allocate VMID via pvesh /cluster/nextid" >&2
  exit 1
fi
echo "==> Allocated VMID: ${VMID}"

# 5) Create VM + import disk + attach + boot order
TEMPLATE_NAME="${OS}-$(timestamp_day)"
echo "==> Creating VM shell and importing disk (this will become a template): ${TEMPLATE_NAME}"

ssh ${PROXMOX_SSH_OPTS} "${REMOTE}" "
  set -euo pipefail

  qm create ${VMID} \
    --name '${TEMPLATE_NAME}' \
    --memory ${TEMPLATE_MEMORY_MB} \
    --cores ${TEMPLATE_CPU} \
    --net0 ${TEMPLATE_MODEL},bridge=${TEMPLATE_BRIDGE} \
    --ostype l26 \
    --scsihw ${TEMPLATE_SCSIHw} \
    --agent 0 \
    --tags "orchestrator,template,${OS}" \
    --onboot 0

  qm importdisk ${VMID} '${REMOTE_TMP}' '${STORAGE}'

  IMPORTED_VOL=\$(qm config ${VMID} | awk -v st='${STORAGE}:' '
    \$1 ~ /^unused[0-9]+:$/ && \$2 ~ \"^\" st \"vm-\" ${VMID} \"-disk-\" {
      print \$2; exit
    }
  ')

  if [ -z \"\${IMPORTED_VOL}\" ]; then
    echo 'ERROR: Could not find imported disk volume in qm config (expected unusedX: ${STORAGE}:vm-${VMID}-disk-N)' >&2
    qm config ${VMID} >&2 || true
    exit 1
  fi

  qm set ${VMID} --scsi0 \"\${IMPORTED_VOL}\"
  qm set ${VMID} --boot order=scsi0

  # --- UEFI (OVMF) + EFI vars disk (Secure Boot OFF) ---
  if [[ "${OS}" == "haos" ]]; then
    echo "[INFO] Applying HAOS UEFI config for VM ${VMID}"
    qm set ${VMID} --bios ovmf --machine q35
    qm set ${VMID} --delete efidisk0 2>/dev/null || true
    qm set ${VMID} --efidisk0 '${STORAGE}':1,format=raw,efitype=4m,pre-enrolled-keys=0
  fi

  qm template ${VMID}

  rm -f '${REMOTE_TMP}'
"

# 6) Cleanup local temp if desired
if [[ "${KEEP_LOCAL_QCOW2}" = "1" ]]; then
  echo "==> Keeping local qcow2: ${LOCAL_QCOW2}"
else
  rm -f "${LOCAL_QCOW2}" || true
fi

# 7) Write L1 template manifest for L2 consumption + update stable pointer
ts="$(date -u +"%Y%m%d-%H%M%S")"
template_created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

artifacts_dir="${os_root}/artifacts"
manifest_path="${artifacts_dir}/vm-template-${ts}.json"
stable_path="${artifacts_dir}/vm-template-stable.json"

mkdir -p "${artifacts_dir}"

description="${DESCRIPTION:-Proxmox template created from restored QCOW2 (disk capture)}"

cat >"${manifest_path}" <<EOF
{
  "created_at": "${template_created_at}",
  "description": "${description}",
  "name": "${TEMPLATE_NAME}",
  "node": "${PROXMOX_NODE}",
  "storage": "${STORAGE}",
  "vmid": ${VMID},
  "source_s3_uri": "${s3_uri}"
}
EOF

if [[ "${UPDATE_STABLE}" == "yes" ]]; then
  spec_dir="infra/os/${OS}/spec"
  mkdir -p "${spec_dir}"
  ln -sf "../artifacts/${manifest_path##*/}" "${spec_dir}/vm-template-stable.json"
  echo "Updated stable symlink -> ${spec_dir}/vm-template-stable.json"
else
  echo "Skipping stable symlink update (UPDATE_STABLE=${UPDATE_STABLE})"
fi

echo
echo "==> Template manifest written: ${manifest_path}"
echo
echo "==> Done."
echo "Template created:"
echo "  Proxmox node: ${PROXMOX_NODE}"
echo "  VMID:         ${VMID}"
echo "  Name:         ${TEMPLATE_NAME}"
echo "  Source:       ${s3_uri}"
echo
echo "Next step (L2): Terraform can clone from template VMID ${VMID}."
