#!/usr/bin/env bash
set -euo pipefail

# Converge passthrough disks for a VM based on hosts.json intent (run from ops host).
#
# Usage:
#   converge-disks.sh <proxmox-node> <vmid> <manifest.json>
#
# Optional env:
#   PROXMOX_USER     default: root
#   PROXMOX_SSH_OPTS default: disables host key checking

PROXMOX_NODE="${1:?Usage: $0 <proxmox-node> <vmid> <manifest.json>}"
VMID="${2:?Usage: $0 <proxmox-node> <vmid> <manifest.json>}"
MANIFEST="${3:?Usage: $0 <proxmox-node> <vmid> <manifest.json>}"

PROXMOX_USER="${PROXMOX_USER:-root}"
DEFAULT_SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PROXMOX_SSH_OPTS="${PROXMOX_SSH_OPTS:-$DEFAULT_SSH_OPTS}"
REMOTE="${PROXMOX_USER}@${PROXMOX_NODE}"

need_local() { command -v "$1" >/dev/null 2>&1 || {
  echo "ERROR: missing dependency on ops host: $1" >&2
  exit 1
}; }
need_local jq
[[ -f "$MANIFEST" ]] || {
  echo "ERROR: manifest not found: $MANIFEST" >&2
  exit 1
}

echo "==> Converge disks"
echo "==> Proxmox node: ${PROXMOX_NODE}"
echo "==> VMID:         ${VMID}"
echo "==> Manifest:     ${MANIFEST}"
echo "==> SSH opts:     ${PROXMOX_SSH_OPTS}"
echo

echo "==> Resolving hostname from VMID via qm config..."
HOSTNAME="$(
  ssh ${PROXMOX_SSH_OPTS} "${REMOTE}" \
    "set -euo pipefail; qm config ${VMID} | awk -F': ' '/^name:/ {print \$2; exit}'"
)"

if [[ -z "${HOSTNAME}" ]]; then
  echo "ERROR: Could not determine hostname from qm config for VMID ${VMID}" >&2
  exit 1
fi
echo "==> Hostname:     ${HOSTNAME}"

# Validate hostname exists in JSON
if ! jq -e --arg h "$HOSTNAME" '.hosts[$h]' "$MANIFEST" >/dev/null; then
  echo "ERROR: Host '${HOSTNAME}' not found in manifest: ${MANIFEST}" >&2
  exit 1
fi

# Extract devices array for this host (local)
DEVICES_JSON="$(
  jq -c --arg h "$HOSTNAME" '.hosts[$h].proxmox.disks.devices // empty' "$MANIFEST"
)"
if [[ -z "$DEVICES_JSON" || "$DEVICES_JSON" == "null" ]]; then
  echo "ERROR: No hosts.${HOSTNAME}.proxmox.disks.devices found in manifest" >&2
  exit 1
fi

echo
echo "==> Stopping VM ${VMID} and waiting for it to be stopped..."
ssh ${PROXMOX_SSH_OPTS} "${REMOTE}" "
  set -euo pipefail
  status=\$(qm status ${VMID} | awk '{print \$2}')
  if [[ \"\$status\" == \"running\" ]]; then
    qm stop ${VMID}
  fi
  while true; do
    s=\$(qm status ${VMID} | awk '{print \$2}')
    [[ \"\$s\" == \"stopped\" ]] && break
    sleep 2
  done
"
echo "==> VM is stopped"

# Converge disks on the Proxmox node
ssh ${PROXMOX_SSH_OPTS} "${REMOTE}" "
  set -euo pipefail

  VMID='${VMID}'
  DEVICES_JSON='${DEVICES_JSON}'

  need() { command -v \"\$1\" >/dev/null 2>&1 || { echo \"ERROR: missing dependency on Proxmox node: \$1\" >&2; exit 1; }; }
  need qm
  need jq

  CFG=\"\$(qm config \"\${VMID}\")\"

  opts_string() {
    local obj=\"\$1\"
    local cache format iothread
    cache=\"\$(jq -r '.cache // empty' <<<\"\$obj\")\"
    format=\"\$(jq -r '.format // empty' <<<\"\$obj\")\"
    iothread=\"\$(jq -r '.iothread // empty' <<<\"\$obj\")\"

    local parts=()
    [[ -n \"\$cache\" ]] && parts+=(\"cache=\$cache\")
    [[ -n \"\$format\" ]] && parts+=(\"format=\$format\")
    [[ -n \"\$iothread\" ]] && parts+=(\"iothread=\$iothread\")
    (IFS=,; echo \"\${parts[*]}\")
  }

  echo
  echo \"==> Current scsi lines:\"
  echo \"\$CFG\" | sed -n 's/^\\(scsi[0-9]\\+\\):/\\1:/p'
  echo

  jq -c '.[]' <<<\"\$DEVICES_JSON\" | while read -r dev; do
    slot=\"\$(jq -r '.slot' <<<\"\$dev\")\"
    by_id=\"\$(jq -r '.by_id' <<<\"\$dev\")\"
    opts=\"\$(jq -c '.opts // {}' <<<\"\$dev\")\"

    [[ \"\$slot\" =~ ^[0-9]+$ ]] || { echo \"ERROR: invalid slot: \$slot\" >&2; exit 1; }
    [[ -n \"\$by_id\" && \"\$by_id\" != \"null\" ]] || { echo \"ERROR: missing by_id for slot \$slot\" >&2; exit 1; }

    key=\"scsi\${slot}\"
    path=\"/dev/disk/by-id/\${by_id}\"
    optstr=\"\$(opts_string \"\$opts\")\"

    echo \"--> \${key} => \${path}\${optstr:+,\${optstr}}\"

    if [[ ! -e \"\$path\" ]]; then
      echo \"ERROR: disk path not found on Proxmox node: \$path\" >&2
      exit 1
    fi

    current_line=\"\$(grep -E \"^\${key}:\" <<<\"\$CFG\" || true)\"

    if [[ -z \"\$current_line\" ]]; then
      echo \"    Attaching (slot empty)\"
      qm set \"\$VMID\" --\"\$key\" \"\${path}\${optstr:+,\${optstr}}\"
      CFG=\"\$(qm config \"\${VMID}\")\"
      continue
    fi

    # Must point to the same by-id path, otherwise refuse
    if ! grep -qF \"\$path\" <<<\"\$current_line\"; then
      echo \"ERROR: slot \${key} already populated with a different disk:\" >&2
      echo \"  Found:    \$current_line\" >&2
      echo \"  Expected: \${key}: \${path}\${optstr:+,\${optstr}}\" >&2
      exit 1
    fi

    # Enforce exact options (removes extras like serial=...)
    desired=\"\${key}: \${path}\${optstr:+,\${optstr}}\"
    if [[ \"\$current_line\" == \"\$desired\" ]]; then
      echo \"    OK (already matches)\"
    else
      echo \"    Updating options to match manifest (removes extras like serial=...)\"
      qm set \"\$VMID\" --\"\$key\" \"\${path}\${optstr:+,\${optstr}}\"
      CFG=\"\$(qm config \"\${VMID}\")\"
    fi
  done

  echo
  echo \"==> Disk convergence complete\"
"

echo
echo "==> Done."
