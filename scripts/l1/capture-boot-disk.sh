#!/usr/bin/env bash
set -euo pipefail

# Capture a TrueNAS (or any VM) boot disk from a Proxmox node as a QCOW2 image.
#
# Usage:
#   capture-truenas-boot.sh <proxmox-node> <vmid> <local-output-dir>
#
# Example:
#   capture-truenas-boot.sh polaris 105 artifacts/truenas/boot
#
# Requirements:
#   - Run this from your operations host.
#   - SSH key-based access to the Proxmox node (default user: root).
#   - Proxmox node must have: qm, pvesm, qemu-img.
#   - VM must be powered OFF (script enforces this).

PROXMOX_NODE="${PVE_SSH_IP}"
OS="${1:?Usage: $0 <os> <vmid>}"
VMID="${2:?Usage: $0 <os> <vmid>}"
LOCAL_OUT_DIR="${LOCAL_OUT_DIR:-/home/lab/.appliances/capture}"
KEEP_LOCAL_QCOW2="${KEEP_LOCAL_QCOW2:-0}"

# Optional: override these via env vars if you want non-root access or extra ssh options.
PROXMOX_USER="${PROXMOX_USER:-root}"
PROXMOX_SSH_OPTS="${PROXMOX_SSH_OPTS:-}"

REMOTE="${PROXMOX_USER}@${PROXMOX_NODE}"

timestamp() {
  date +"%Y%m%d-%H%M%S"
}

# Derive a stable "hostname" folder from the Proxmox VM name (qm config name: ...)
VM_NAME_RAW="$(ssh ${PROXMOX_SSH_OPTS} "${REMOTE}" "qm config ${VMID} | awk -F': ' '/^name: /{print \$2; exit}'")"

if [ -z "${VM_NAME_RAW}" ]; then
  # Fallback: use vmid if name isn't set (should be rare)
  VM_NAME_RAW="vm-${VMID}"
fi

echo "==> Capturing boot disk for VM ${VM_NAME_RAW} (${VMID}) on node ${PROXMOX_NODE}"

# Ensure local output dir exists
if [ ! -d "${LOCAL_OUT_DIR}" ]; then
  echo "==> Creating local output directory: ${LOCAL_OUT_DIR}"
  mkdir -p "${LOCAL_OUT_DIR}"
fi

# 1) Ensure VM is stopped
echo "==> Checking VM power state..."
VM_STATUS=$(ssh ${PROXMOX_SSH_OPTS} "${REMOTE}" "qm status ${VMID} --verbose 2>/dev/null || true")

if ! echo "${VM_STATUS}" | grep -q "status: stopped"; then
  echo "ERROR: VMID ${VMID} is not stopped."
  echo "Current status from 'qm status ${VMID}':"
  echo "${VM_STATUS}"
  echo "Please shut down the VM and rerun this script."
  exit 1
fi

echo "==> VM ${VMID} is stopped."

# 2) Determine boot disk volume ID via qm config
echo "==> Detecting boot disk volume ID..."
BOOT_VOLID=$(ssh ${PROXMOX_SSH_OPTS} "${REMOTE}" "
  set -euo pipefail
  qm config ${VMID} \
    | awk '
        /^(scsi|virtio|sata)[0-9]+: / {
          # field 2 is something like:
          #   local-lvm:vm-104-disk-0,iothread=1,size=16G
          # Strip after first comma.
          split(\$2, a, \",\")
          print a[1]
          exit
        }
      '
")

if [ -z \"${BOOT_VOLID}\" ]; then
  echo \"ERROR: Could not determine boot disk volid for VMID ${VMID}.\"
  exit 1
fi

# 3) Resolve volume ID to an actual path using pvesm
echo "==> Resolving storage path via pvesm..."
REMOTE_DISK_PATH=$(ssh ${PROXMOX_SSH_OPTS} "${REMOTE}" "
  set -euo pipefail
  pvesm path '${BOOT_VOLID}'
")

if [ -z "${REMOTE_DISK_PATH}" ]; then
  echo "ERROR: pvesm could not resolve path for volid '${BOOT_VOLID}'."
  exit 1
fi

echo "==> Boot disk path on Proxmox node: ${REMOTE_DISK_PATH}"

# 4) Convert disk to QCOW2 on the Proxmox node
REMOTE_TMP_DIR="/var/tmp"
REMOTE_TS="$(timestamp)"
REMOTE_QCOW2="${REMOTE_TMP_DIR}/boot-disk-export-${VMID}-${REMOTE_TS}.qcow2"

echo "==> Converting disk to QCOW2 on Proxmox node..."
ssh ${PROXMOX_SSH_OPTS} "${REMOTE}" "
  set -euo pipefail
  mkdir -p '${REMOTE_TMP_DIR}'
  echo 'Running: qemu-img convert -O qcow2 \"${REMOTE_DISK_PATH}\" \"${REMOTE_QCOW2}\"'
  qemu-img convert -O qcow2 '${REMOTE_DISK_PATH}' '${REMOTE_QCOW2}'
  echo 'QCOW2 created at: ${REMOTE_QCOW2}'
  echo 'qemu-img info:'
  qemu-img info '${REMOTE_QCOW2}'
"

# 5) Copy QCOW2 back to local host
LOCAL_TS="$(timestamp)"
LOCAL_QCOW2="${LOCAL_OUT_DIR}/boot-disk-export-${VMID}-${LOCAL_TS}.qcow2"

echo "==> Copying QCOW2 to local host: ${LOCAL_QCOW2}"
scp ${PROXMOX_SSH_OPTS} "${REMOTE}:${REMOTE_QCOW2}" "${LOCAL_QCOW2}"

echo "==> Verifying local QCOW2 with qemu-img (if present)..."
if command -v qemu-img >/dev/null 2>&1; then
  qemu-img info "${LOCAL_QCOW2}" || {
    echo "WARNING: qemu-img info failed locally; file might be corrupt."
  }
else
  echo "NOTE: qemu-img not installed locally; skipping local validation."
fi

# 6) Clean up remote QCOW2
echo "==> Cleaning up temporary QCOW2 on Proxmox node..."
ssh ${PROXMOX_SSH_OPTS} "${REMOTE}" "
  set -euo pipefail
  rm -f '${REMOTE_QCOW2}'
"

echo "==> Done."
echo "Captured boot disk stored at: ${LOCAL_QCOW2}"

# --- S3 upload + retention (keep last 3 per hostname) -------------------------

S3_BUCKET="${S3_BUCKET:?Set S3_BUCKET (e.g. export S3_BUCKET=my-bucket)}"
S3_PREFIX="${S3_PREFIX:-appliance-backups}"

# Sanitize for S3 key prefix safety: lower, keep [a-z0-9._-], replace others with '-'
HOST_FOLDER="$(printf '%s' "${OS}" |
  tr '[:upper:]' '[:lower:]' |
  sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//')"

# Optional: customize the object filename
OBJ_BASENAME="$(basename "${LOCAL_QCOW2}")"
S3_KEY="${S3_PREFIX}/${HOST_FOLDER}/${OBJ_BASENAME}"
S3_URI="s3://${S3_BUCKET}/${S3_KEY}"

echo "==> Uploading QCOW2 to S3: ${S3_URI}"
aws s3 cp --only-show-errors "${LOCAL_QCOW2}" "${S3_URI}"

echo "==> Enforcing retention: keep newest 3 in s3://${S3_BUCKET}/${S3_PREFIX}/${HOST_FOLDER}/"

# Get keys sorted newest-first, skip the first 3, output the rest (one per line)
OLD_KEYS="$(
  aws s3api list-objects-v2 \
    --bucket "${S3_BUCKET}" \
    --prefix "${S3_PREFIX}/${HOST_FOLDER}/" \
    --query "reverse(sort_by(Contents,&LastModified))[3:].Key" \
    --output text
)"

# If nothing to delete, AWS returns empty output (or "None")
if [ -z "${OLD_KEYS}" ] || [ "${OLD_KEYS}" = "None" ]; then
  echo "==> Nothing to delete (<= 3 backups present)."
else
  # OLD_KEYS comes back as whitespace-separated keys with --output text
  # Build JSON delete payload without jq
  DELETE_PAYLOAD='{"Objects":['
  first=1
  for k in ${OLD_KEYS}; do
    if [ "${first}" -eq 1 ]; then
      first=0
    else
      DELETE_PAYLOAD+=','
    fi
    # Keys are safe here (no quotes) because we don't include quotes in keys,
    # but to be safe we’ll JSON-escape any double quotes/backslashes.
    esc_k="$(printf '%s' "${k}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    DELETE_PAYLOAD+='{"Key":"'"${esc_k}"'"}'
  done
  DELETE_PAYLOAD+=']}'

  echo "==> Deleting old backup(s)..."
  aws s3api delete-objects \
    --bucket "${S3_BUCKET}" \
    --delete "${DELETE_PAYLOAD}" \
    >/dev/null

  echo "==> Retention cleanup complete."
fi

# --- end S3 upload + retention ------------------------------------------------

if [ "${KEEP_LOCAL_QCOW2}" = "1" ]; then
  echo "==> Keeping local qcow2: ${LOCAL_QCOW2}"
else
  rm -f "${LOCAL_QCOW2}" || true
fi

# --- Write L1 template manifest for L2 consumption ----------------------------

# Timestamp used for filename + metadata
ts="$(date -u +"%Y%m%d-%H%M%S")"
created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

artifacts_dir="infra/os/${OS}/artifacts"
manifest_path="${artifacts_dir}/disk-capture-${ts}.json"

mkdir -p "${artifacts_dir}"

# You can adjust description as you like; keeping it simple/default.
description="${DESCRIPTION:-Proxmox VM disk captured and exported to S3}"

cat >"${manifest_path}" <<EOF
{
  "created_at": "${created_at}",
  "description": "${description}",
  "os": "${OS}",
  "node": "${PROXMOX_NODE}",
  "vmid": ${VMID},
  "hostname": "${VM_NAME_RAW}",
  "s3_uri": "${S3_URI}"
}
EOF

echo "==> Manifest written: ${manifest_path}"

# --- end manifest ------------------------------------------------------------
