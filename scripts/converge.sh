#!/usr/bin/env bash
set -euo pipefail

GROUP="${1:?Usage: $0 <group> <layer>}"
LAYER="${2:?Usage: $0 <group> <layer>}"

INVENTORY="ansible/inventory/"

case "${LAYER}" in
  l3|l4) ;;
  *)
    echo "Invalid layer: ${LAYER}. Expected 'l3' or 'l4'." >&2
    exit 1
    ;;
esac

PLAYBOOK="ansible/${LAYER}/converge.yaml"

if [[ ! -d "${INVENTORY}" ]]; then
  echo "Inventory not found at: ${INVENTORY}" >&2
  exit 1
fi

if [[ ! -f "${PLAYBOOK}" ]]; then
  echo "Converge playbook not found at: ${PLAYBOOK}" >&2
  exit 1
fi

TAGS="${TAGS:-}"
LIMIT="${LIMIT:-}"

# Build extra args safely under `set -u`
extra=()
extra+=(-e converge_group="${GROUP}")
if [[ -n "${TAGS}" ]]; then
  extra+=(--tags "${TAGS}")
fi
if [[ -n "${LIMIT}" ]]; then
  extra+=(--limit "${LIMIT}")
fi

echo "=== [${LAYER}] Converging hosts ==="
echo "Inventory : ${INVENTORY}"
echo "Group:      ${GROUP}"
echo "Playbook  : ${PLAYBOOK}"
echo "Tags   : ${TAGS:-<none>}"
echo "Limit  : ${LIMIT:-<none>}"
echo "Extra  : ${extra[@]}"

exit 0

if ((${#extra[@]})); then
  ansible-playbook \
    -i "${INVENTORY}" \
    "${PLAYBOOK}" \
    "${extra[@]}"
else
  ansible-playbook \
    -i "${INVENTORY}" \
    "${PLAYBOOK}"
fi

echo "=== [L3] Converge complete ==="
