#!/usr/bin/env bash
set -euo pipefail

GROUP="${1:?Usage: $0 <group>}"

INVENTORY="ansible/inventory/"
PLAYBOOK="ansible/l3/shutdown.yaml"

if [[ ! -d "${INVENTORY}" ]]; then
  echo "Inventory not found at: ${INVENTORY}" >&2
  exit 1
fi

if [[ ! -f "${PLAYBOOK}" ]]; then
  echo "L3 playbook not found at: ${PLAYBOOK}" >&2
  exit 1
fi

TAGS="${TAGS:-}"
LIMIT="${LIMIT:-}"

echo "=== [l3] Resolving shutdown hosts ==="
echo "Group : ${GROUP}"
echo "Limit : ${LIMIT:-<none>}"
echo

# Resolve host list the SAME WAY reboot resolves execution scope
if [[ -n "${LIMIT}" ]]; then
  hosts="$(ansible -i "${INVENTORY}" "${GROUP}" --limit "${LIMIT}" --list-hosts \
    | awk 'found && NF {print $1} /^  hosts \([0-9]+\):$/ {found=1; next}')"
else
  hosts="$(ansible -i "${INVENTORY}" "${GROUP}" --list-hosts \
    | awk 'found && NF {print $1} /^  hosts \([0-9]+\):$/ {found=1; next}')"
fi

if [[ -z "${hosts}" ]]; then
  echo "No hosts matched."
  exit 0
fi

echo "Hosts that will be shut down:"
printf '%s\n' "${hosts}" | sed 's/^/  - /'
echo

read -r -p "Type 'yes' to confirm shutdown: " confirm
if [[ "${confirm}" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

# Build playbook args (same pattern as reboot)
extra=()
extra+=(-e converge_group="${GROUP}")
extra+=(-e shutdown_action="now")

if [[ -n "${TAGS}" ]]; then
  extra+=(--tags "${TAGS}")
fi
if [[ -n "${LIMIT}" ]]; then
  extra+=(--limit "${LIMIT}")
fi

echo
echo "Command: ansible-playbook -i \"${INVENTORY}\" \"${PLAYBOOK}\" ${extra[*]}"
echo

ansible-playbook \
  -i "${INVENTORY}" \
  "${PLAYBOOK}" \
  "${extra[@]}"

echo "=== [l3] Shutdown complete ==="
