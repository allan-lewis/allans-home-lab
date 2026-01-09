#!/usr/bin/env bash
set -euo pipefail

# If someone accidentally sources this script, bail (prevents scope weirdness).
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  echo "ERROR: Do not source this script; run it directly." >&2
  return 1
fi

GROUP="${1:?Usage: $0 <group>}"

# Read desired behavior from env; default to dryrun
REBOOT_ACTION="${REBOOT_ACTION:-dryrun}"

INVENTORY="ansible/inventory/"
PLAYBOOK="ansible/l3/reboot.yaml"

if [[ ! -d "${INVENTORY}" ]]; then
  echo "Inventory not found at: ${INVENTORY}" >&2
  exit 1
fi

if [[ ! -f "${PLAYBOOK}" ]]; then
  echo "L3 playbook not found at: ${PLAYBOOK}" >&2
  exit 1
fi

# Normalize REBOOT_ACTION to lowercase in a portable way
reboot_action_norm="$(printf '%s' "${REBOOT_ACTION}" | tr '[:upper:]' '[:lower:]')"

# Validate
case "${reboot_action_norm}" in
  dryrun|check|force) ;;
  *)
    echo "Invalid REBOOT_ACTION: '${REBOOT_ACTION}'. Expected one of: dryrun|check|force" >&2
    exit 1
    ;;
esac

TAGS="${TAGS:-}"
LIMIT="${LIMIT:-}"

# Map env action -> ansible vars / flags
force_reboot="false"
reboot_action="check"

# IMPORTANT: declare arrays explicitly (nounset-safe)
declare -a extra_flags=()
declare -a extra=()

case "${reboot_action_norm}" in
  dryrun)
    reboot_action="dryrun"
    force_reboot="false"
    extra_flags+=(--diff)
    ;;
  check)
    reboot_action="check"
    force_reboot="false"
    ;;
  force)
    reboot_action="check"
    force_reboot="true"
    # Serialise reboots to reduce SSH churn
    extra_flags+=(--forks 1)
    ;;
esac

# Build extra args safely
extra+=(-e "converge_group=${GROUP}")
extra+=(-e "reboot_action=${reboot_action}")
extra+=(-e "force_reboot=${force_reboot}")

if [[ -n "${TAGS}" ]]; then
  extra+=(--tags "${TAGS}")
fi
if [[ -n "${LIMIT}" ]]; then
  extra+=(--limit "${LIMIT}")
fi

echo "=== [l3] Reboot hosts ==="
echo "Inventory      : ${INVENTORY}"
echo "Group          : ${GROUP}"
echo "Playbook       : ${PLAYBOOK}"
echo "REBOOT_ACTION  : ${reboot_action_norm}"
echo "reboot_action  : ${reboot_action}"
echo "force_reboot   : ${force_reboot}"
echo "Tags           : ${TAGS:-<none>}"
echo "Limit          : ${LIMIT:-<none>}"
echo "Flags          : ${extra_flags[*]:-<none>}"

# Build a printable representation (shell-escaped) without tripping nounset if arrays are unset.
# (The ${arr[@]+...} form is the key: it expands to nothing if arr is unset.)
printf 'Command        :'
printf ' %q' ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}" \
  ${extra_flags[@]+"${extra_flags[@]}"} \
  ${extra[@]+"${extra[@]}"}
printf '\n'

# Execute (same safe expansion)
ansible-playbook \
  -i "${INVENTORY}" \
  "${PLAYBOOK}" \
  ${extra_flags[@]+"${extra_flags[@]}"} \
  ${extra[@]+"${extra[@]}"}

echo "=== [l3] Reboot complete ==="
