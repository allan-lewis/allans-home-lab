#!/usr/bin/env bash
set -euo pipefail

# Restore a captured QCOW2 from S3 and convert it into a Proxmox template.
#
# Usage:
#   restore-to-template.sh <proxmox-node> <hostname> <storage> <os> [filename]
#
# Examples:
#   # Use latest qcow2 under s3://$S3_BUCKET/$S3_PREFIX/langolier/
#   restore-to-template.sh polaris langolier local-lvm
#
#   # Use an exact filename
#   restore-to-template.sh polaris langolier local-lvm boot-disk-export-langolier-20260117-150734.qcow2
#
# Required env:
#   S3_BUCKET   e.g. export S3_BUCKET="gitops-homelab-orchestrator-disks"
#
# Optional env:
#   S3_PREFIX            default: proxmox-images
#   PROXMOX_USER         default: root
#   PROXMOX_SSH_OPTS     default: disables host key checking
#   TEMPLATE_CPU         default: 2
#   TEMPLATE_MEMORY_MB   default: 2048
#   TEMPLATE_BRIDGE      default: vmbr0
#   TEMPLATE_MODEL       default: virtio
#   TEMPLATE_SCSIHw      default: virtio-scsi-single
#   KEEP_LOCAL_QCOW2     default: 0 (set to 1 to keep local downloaded qcow2)

PROXMOX_NODE="${1:?Usage: $0 <proxmox-node> <hostname> <storage> <os> [filename]}"
HOSTNAME="${2:?Usage: $0 <proxmox-node> <hostname> <storage> <os> [filename]}"
STORAGE="${3:?Usage: $0 <proxmox-node> <hostname> <storage> <os> [filename]}"
OS="${4:?Usage: $0 <proxmox-node> <hostname> <storage> <os> [filename]}"
FILENAME="${5:-}"

S3_BUCKET="${S3_BUCKET:?Set S3_BUCKET (e.g. export S3_BUCKET=gitops-homelab-orchestrator-disks)}"
S3_PREFIX="${S3_PREFIX:-proxmox-images}"

PROXMOX_USER="${PROXMOX_USER:-root}"
DEFAULT_SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PROXMOX_SSH_OPTS="${PROXMOX_SSH_OPTS:-$DEFAULT_SSH_OPTS}"

TEMPLATE_CPU="${TEMPLATE_CPU:-2}"
TEMPLATE_MEMORY_MB="${TEMPLATE_MEMORY_MB:-2048}"
TEMPLATE_BRIDGE="${TEMPLATE_BRIDGE:-vmbr0}"
TEMPLATE_MODEL="${TEMPLATE_MODEL:-virtio}"
TEMPLATE_SCSIHw="${TEMPLATE_SCSIHw:-virtio-scsi-single}"
KEEP_LOCAL_QCOW2="${KEEP_LOCAL_QCOW2:-0}"

REMOTE="${PROXMOX_USER}@${PROXMOX_NODE}"

timestamp() { date +"%Y%m%d-%H%M%S"; }

echo "==> Restore-to-template"
echo "==> Proxmox node: ${PROXMOX_NODE}"
echo "==> Hostname:     ${HOSTNAME}"
echo "==> Storage:      ${STORAGE}"
echo "==> S3:           s3://${S3_BUCKET}/${S3_PREFIX}/${HOSTNAME}/"
echo "==> SSH opts:     ${PROXMOX_SSH_OPTS}"

# 1) Determine which S3 object to use
S3_KEY=""
if [ -n "${FILENAME}" ]; then
  S3_KEY="${S3_PREFIX}/${HOSTNAME}/${FILENAME}"
  echo "==> Using specified filename: ${FILENAME}"
  echo "==> Verifying object exists: s3://${S3_BUCKET}/${S3_KEY}"
  aws s3api head-object --bucket "${S3_BUCKET}" --key "${S3_KEY}" >/dev/null
else
  echo "==> No filename provided; selecting most recent object by LastModified..."
  S3_KEY="$(
    aws s3api list-objects-v2 \
      --bucket "${S3_BUCKET}" \
      --prefix "${S3_PREFIX}/${HOSTNAME}/" \
      --query "reverse(sort_by(Contents,&LastModified))[0].Key" \
      --output text
  )"

  if [ -z "${S3_KEY}" ] || [ "${S3_KEY}" = "None" ]; then
    echo "ERROR: No objects found under s3://${S3_BUCKET}/${S3_PREFIX}/${HOSTNAME}/" >&2
    exit 1
  fi
fi

S3_URI="s3://${S3_BUCKET}/${S3_KEY}"
BASE_NAME="$(basename "${S3_KEY}")"

echo "==> Selected S3 object: ${S3_URI}"

# 2) Download qcow2 locally (ops host)
LOCAL_TMP_DIR="${TMPDIR:-/home/lab/restore-template}"
mkdir -p ${LOCAL_TMP_DIR}
LOCAL_QCOW2="${LOCAL_TMP_DIR}/${BASE_NAME}"

if [ -f "${LOCAL_QCOW2}" ]; then
  echo "==> Local QCOW2 already exists, skipping download: ${LOCAL_QCOW2}"
else
  echo "==> Downloading to local temp: ${LOCAL_QCOW2}"
  aws s3 cp --only-show-errors "${S3_URI}" "${LOCAL_QCOW2}"
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
if [ -z "${VMID}" ]; then
  echo "ERROR: Failed to allocate VMID via pvesh /cluster/nextid" >&2
  exit 1
fi
echo "==> Allocated VMID: ${VMID}"

# 5) Create VM + import disk + attach + boot order
TEMPLATE_NAME="tmpl-${HOSTNAME}-$(timestamp)"
echo "==> Creating VM shell and importing disk (this will become a template): ${TEMPLATE_NAME}"

ssh ${PROXMOX_SSH_OPTS} "${REMOTE}" "
  set -euo pipefail

  # Create a minimal VM shell
  qm create ${VMID} \
    --name '${TEMPLATE_NAME}' \
    --memory ${TEMPLATE_MEMORY_MB} \
    --cores ${TEMPLATE_CPU} \
    --net0 ${TEMPLATE_MODEL},bridge=${TEMPLATE_BRIDGE} \
    --ostype l26 \
    --scsihw ${TEMPLATE_SCSIHw} \
    --agent 0 \
    --onboot 0

  # Import the qcow2 into the chosen storage
  qm importdisk ${VMID} '${REMOTE_TMP}' '${STORAGE}'

  # Find the newest imported disk volume for this VM on this storage
  # Common outcome: ${STORAGE}:vm-${VMID}-disk-0
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

  # Attach imported disk as scsi0 and set boot order
  qm set ${VMID} --scsi0 \"\${IMPORTED_VOL}\"
  qm set ${VMID} --boot order=scsi0

  # Remove the unusedX entry if present (optional cosmetic cleanup)
  # Proxmox may leave the disk as unused0 even after attaching; harmless if it remains.
  # (No-op if none)
  true

  # Convert to template
  qm template ${VMID}

  # Cleanup the uploaded qcow2 file from /var/tmp
  rm -f '${REMOTE_TMP}'
"

# 6) Cleanup local temp if desired
if [ "${KEEP_LOCAL_QCOW2}" = "1" ]; then
  echo "==> Keeping local qcow2: ${LOCAL_QCOW2}"
else
  rm -f "${LOCAL_QCOW2}" || true
fi

# --- Write L1 template manifest for L2 consumption ----------------------------

# Required: OS (you said you'll add it as an argument)
# Example: OS="haos"
: "${OS:?OS argument is required (e.g. haos)}"

# Timestamp used for filename + metadata
ts_utc="$(date -u +%Y%m%dT%H%M%SZ)"
created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

artifacts_dir="infra/os/${OS}/artifacts"
manifest_path="${artifacts_dir}/vm-template-${ts_utc}.json"

mkdir -p "${artifacts_dir}"

# You can adjust description as you like; keeping it simple/default.
description="${DESCRIPTION:-Proxmox template created from restored QCOW2}"

cat >"${manifest_path}" <<EOF
{
  "created_at": "${created_at}",
  "description": "${description}",
  "name": "${TEMPLATE_NAME}",
  "node": "${PROXMOX_NODE}",
  "storage": "${STORAGE}",
  "vmid": ${VMID}
}
EOF

echo "==> Manifest written: ${manifest_path}"

# --- end manifest ------------------------------------------------------------

echo "==> Done."
echo "Template created:"
echo "  Proxmox node: ${PROXMOX_NODE}"
echo "  VMID:         ${VMID}"
echo "  Name:         ${TEMPLATE_NAME}"
echo "  Source:       ${S3_URI}"
echo
echo "Next step (L2): Terraform can clone from template VMID ${VMID}."
