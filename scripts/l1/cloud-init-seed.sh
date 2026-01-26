#!/usr/bin/env bash
set -euo pipefail

TARGET_HOST="${TARGET_HOST:-${1:-}}"
if [[ -z "${TARGET_HOST}" ]]; then
  echo "Usage: TARGET_HOST=<hostname> $0" >&2
  exit 1
fi

INVENTORY="${INVENTORY:-ansible/inventory}"
PLAYBOOK="${PLAYBOOK:-ansible/l1/seed_cidata_local.yaml}"

exec ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}" \
  --extra-vars "target_host=${TARGET_HOST}"
