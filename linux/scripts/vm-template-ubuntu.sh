#!/usr/bin/env bash
set -euo pipefail

###
# ubuntu-build-template.sh
#
# Requirements (env vars):
#   PVE_ACCESS_HOST   e.g. https://maturin.hosts.allanshomelab.com
#   PVE_NODE          e.g. maturin
#   PVE_STORAGE_VM    e.g. local-lvm
#   PVE_SSH_USER      e.g. gitops or root (must be able to run qm)
#   PVE_SSH_IP        e.g. 10.0.0.10 (direct IP, not reverse proxy)
#
# Optional env:
#   UBUNTU_CLOUD_IMAGE_URL  (default: Resolute cloud image)
#   UBUNTU_TEMPLATE_NAME    (default: ubuntu-YYYYMMDD)
#   UBUNTU_TEMPLATE_VMID    (if unset, we call pvesh get /cluster/nextid)
#   UPDATE_STABLE           (set to yes to update vm-template-stable.json)
#
# Local requirements:
#   curl
#   git
#   rsync
#   ssh
#   sha256sum
#   virt-customize (libguestfs)
#
# Ubuntu 26.04 / dracut note:
#
#   The stock Resolute cloud image includes dracut's systemd-networkd
#   module in the initramfs. During early boot that module can install
#   zzzz-dracut-default.network with DHCP=yes, causing the VM NIC to
#   acquire a DHCP address before cloud-init applies the Proxmox static
#   network configuration.
#
#   That can race with cloud-init's ens18 -> eth0 rename and leave the
#   VM using DHCP rather than the configured static address.
#
#   We customize a COPY of the downloaded cloud image before importing
#   it into Proxmox:
#
#     omit_dracutmodules+=" systemd-networkd "
#
#   and rebuild the image's initramfs with dracut.
#
#   The original downloaded Ubuntu image is retained unchanged.
###

: "${PVE_ACCESS_HOST:?Missing PVE_ACCESS_HOST}"
: "${PVE_NODE:?Missing PVE_NODE}"
: "${PVE_STORAGE_VM:?Missing PVE_STORAGE_VM}"
: "${PVE_SSH_USER:?Missing PVE_SSH_USER}"
: "${PVE_SSH_IP:?Missing PVE_SSH_IP}"

UBUNTU_CLOUD_IMAGE_URL="${UBUNTU_CLOUD_IMAGE_URL:-https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-amd64.img}"
UBUNTU_TEMPLATE_NAME="${UBUNTU_TEMPLATE_NAME:-ubuntu-$(date -u +"%Y%m%d")}"
UPDATE_STABLE="${1:-}"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BUILD_ROOT="${REPO_ROOT}/.build/template-build-ubuntu/ubuntu"
mkdir -p "${BUILD_ROOT}"

echo "Building to ${BUILD_ROOT}"

IMAGE_NAME="$(basename "${UBUNTU_CLOUD_IMAGE_URL}")"
IMAGE_PATH="${BUILD_ROOT}/${IMAGE_NAME}"
CUSTOM_IMAGE_NAME="custom-${IMAGE_NAME}"
CUSTOM_IMAGE_PATH="${BUILD_ROOT}/${CUSTOM_IMAGE_NAME}"
SHA_PATH="${BUILD_ROOT}/${IMAGE_NAME}.sha256"

echo "=== Ubuntu cloud image template build ==="
echo "Ubuntu image URL    : ${UBUNTU_CLOUD_IMAGE_URL}"
echo "Local image path    : ${IMAGE_PATH}"
echo "Customized image    : ${CUSTOM_IMAGE_PATH}"
echo "Template name       : ${UBUNTU_TEMPLATE_NAME}"
echo "Proxmox node        : ${PVE_NODE}"
echo "Proxmox storage     : ${PVE_STORAGE_VM}"
echo "Update stable link  : ${UPDATE_STABLE}"

#
# Verify local dependencies before doing any work.
#

echo
echo "==> Checking local dependencies..."

for command in curl git rsync ssh sha256sum virt-customize; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: ${command}" >&2
    exit 1
  fi
done

#
# Download pristine Ubuntu cloud image.
#

echo
echo "==> Downloading Ubuntu cloud image to ${IMAGE_PATH} (if needed)..."

if [[ ! -f "${IMAGE_PATH}" ]]; then
  curl -L --fail-with-body -o "${IMAGE_PATH}" "${UBUNTU_CLOUD_IMAGE_URL}"
else
  echo "Image already exists at ${IMAGE_PATH}, skipping download."
fi

#
# Record checksum of the ORIGINAL Ubuntu image.
#

echo
echo "==> Calculating source image SHA256..."

sha256sum "${IMAGE_PATH}" | awk '{print $1}' >"${SHA_PATH}"
SHA256="$(cat "${SHA_PATH}")"

echo "Source image SHA256: ${SHA256}"

#
# Create a disposable copy that we can customize.
#
# Remove an old customized image first so every build starts from the
# pristine cached Ubuntu cloud image.
#

echo
echo "==> Creating working copy of Ubuntu cloud image..."

rm -f "${CUSTOM_IMAGE_PATH}"
cp --reflink=auto "${IMAGE_PATH}" "${CUSTOM_IMAGE_PATH}"

#
# Prevent dracut from including its systemd-networkd module in the
# initramfs.
#
# This prevents dracut from creating:
#
#   /run/systemd/network/zzzz-dracut-default.network
#
# and starting DHCP on the VM NIC before cloud-init/Netplan applies
# the network configuration supplied by Proxmox.
#
# virt-customize operates directly on the QCOW2 image. The VM does
# not need to be booted.
#

echo
echo "==> Disabling dracut initramfs networking..."

virt-customize \
  -a "${CUSTOM_IMAGE_PATH}" \
  --mkdir /etc/dracut.conf.d \
  --write '/etc/dracut.conf.d/omit-initramfs-network.conf:omit_dracutmodules+=" systemd-networkd dyn-netconf "' \
  --run-command 'dracut --force'

echo "Customized image ready: ${CUSTOM_IMAGE_PATH}"

#
# Upload customized image to Proxmox.
#

echo
echo "==> Uploading customized cloud image to Proxmox..."

SSH_HOST="${PVE_SSH_IP#*://}"
SSH_HOST="${SSH_HOST%/}"

rsync -ah --progress \
  -e "ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
  "${CUSTOM_IMAGE_PATH}" \
  "${PVE_SSH_USER}@${SSH_HOST}:/tmp/${IMAGE_NAME}"

#
# Select Proxmox VMID.
#

echo
echo "==> Selecting VMID on Proxmox..."

# If UBUNTU_TEMPLATE_VMID is set, use it; otherwise ask Proxmox
# for the next free one.
if [[ -n "${UBUNTU_TEMPLATE_VMID:-}" ]]; then
  VMID="${UBUNTU_TEMPLATE_VMID}"
  echo "Using provided VMID: ${VMID}"
else
  VMID="$(
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "${PVE_SSH_USER}@${SSH_HOST}" \
      "pvesh get /cluster/nextid"
  )"

  echo "Using next available VMID from Proxmox: ${VMID}"
fi

#
# Create Proxmox template.
#

echo
echo "==> Creating / refreshing Proxmox VM template (VMID=${VMID})..."

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  "${PVE_SSH_USER}@${SSH_HOST}" "bash -s" <<EOF
set -euo pipefail

VMID="${VMID}"
NAME="${UBUNTU_TEMPLATE_NAME}"
STORAGE="${PVE_STORAGE_VM}"
NODE="${PVE_NODE}"
IMAGE_PATH="/tmp/${IMAGE_NAME}"

if [ ! -f "\${IMAGE_PATH}" ]; then
  echo "ERROR: Cloud image not found at \${IMAGE_PATH}" >&2
  exit 1
fi

echo "Proxmox: checking for existing VMID \${VMID}..."

if qm status "\${VMID}" >/dev/null 2>&1; then
  echo "VMID \${VMID} already exists, destroying existing VM/template..."
  qm stop "\${VMID}" || true
  qm destroy "\${VMID}" --purge 1 || qm destroy "\${VMID}" || true
fi

echo "Creating VM \${VMID} (\${NAME}) on node \${NODE}..."

qm create "\${VMID}" \
  --name "\${NAME}" \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --ostype l26 \
  --machine q35 \
  --tags "orchestrator,template,ubuntu"

echo "Importing disk into storage \${STORAGE}..."

qm importdisk \
  "\${VMID}" \
  "\${IMAGE_PATH}" \
  "\${STORAGE}" \
  --format qcow2

echo "Attaching disk as scsi0 and configuring SCSI controller..."

qm set "\${VMID}" \
  --scsihw virtio-scsi-pci \
  --scsi0 "\${STORAGE}:vm-\${VMID}-disk-0"

echo "Attaching cloud-init drive (ide2)..."

qm set "\${VMID}" \
  --ide2 "\${STORAGE}:cloudinit"

echo "Setting boot order to scsi0..."

qm set "\${VMID}" \
  --boot order=scsi0

echo "Configuring serial console and VGA for headless usage..."

qm set "\${VMID}" \
  --serial0 socket \
  --vga serial0

echo "Enabling QEMU guest agent..."

qm set "\${VMID}" \
  --agent 1

echo "Converting VM \${VMID} to template..."

qm template "\${VMID}"

echo "Cleaning up uploaded image..."

rm -f "\${IMAGE_PATH}"

echo "Template \${VMID} (\${NAME}) ready on node \${NODE} with storage \${STORAGE}."
EOF

#
# The customized image is disposable. Keep the pristine Ubuntu image
# cached for future builds.
#

echo
echo "==> Cleaning up customized local image..."

rm -f "${CUSTOM_IMAGE_PATH}"

#
# Generate manifest.
#

echo
echo "==> Generating manifest JSON..."

TIMESTAMP_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
ARTIFACT_DIR="${REPO_ROOT}/linux/ubuntu/artifacts"
SPEC_DIR="${REPO_ROOT}/linux/ubuntu/spec"

mkdir -p "${ARTIFACT_DIR}" "${SPEC_DIR}"

MANIFEST_FILE="${ARTIFACT_DIR}/vm-template-$(date -u +"%Y%m%d-%H%M%S").json"

cat >"${MANIFEST_FILE}" <<EOF
{
  "created_at": "${TIMESTAMP_UTC}",
  "description": "Ubuntu 26.04 Resolute Raccoon cloud-image base with qemu-guest-agent and cloud-init drive; dracut initramfs networking disabled",
  "name": "${UBUNTU_TEMPLATE_NAME}",
  "node": "${PVE_NODE}",
  "storage": "${PVE_STORAGE_VM}",
  "vmid": ${VMID},
  "cloud_image_url": "${UBUNTU_CLOUD_IMAGE_URL}",
  "cloud_image_sha256": "${SHA256}"
}
EOF

echo "Manifest written to: ${MANIFEST_FILE}"
cat "${MANIFEST_FILE}"

#
# Optionally update stable template manifest symlink.
#

if [[ "${UPDATE_STABLE}" == "yes" ]]; then
  STABLE_PATH="${SPEC_DIR}/vm-template-stable.json"

  # Create/update symlink atomically.
  ln -sf "../artifacts/$(basename "${MANIFEST_FILE}")" "${STABLE_PATH}"

  echo
  echo "Stable manifest now points to: ${STABLE_PATH}"
  ls -l "${STABLE_PATH}"
fi

echo
echo "=== Done. ==="
