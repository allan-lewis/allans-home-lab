#!/usr/bin/env bash
set -euo pipefail

PLAYBOOK="${1:?Usage: $0 <playbook> <group> [tags] [limit] [extra_e]}"
GROUP="${2:?Usage: $0 <playbook> <group> [tags] [limit] [extra_e]}"
TAGS="${3:-}"
LIMIT="${4:-}"
EXTRA_E="${5:-}"   # e.g. 'foo=bar baz=qux' OR '@vars.yml' OR '{"a":1}'

# Resolve repo root relative to this script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Build ansible command safely as an array
CMD=(
  ansible-playbook
  -i ansible/inventory/
  -e "converge_group=${GROUP}"
  "${PLAYBOOK}"
)

# Add tags if provided
if [[ -n "$TAGS" ]]; then
  CMD+=(--tags "$TAGS")
fi

# Add limit if provided
if [[ -n "$LIMIT" ]]; then
  CMD+=(--limit "$LIMIT")
fi

# Add extra -e if provided
# NOTE: This is a single -e argument, but it can contain multiple key=value pairs, @file, or JSON.
if [[ -n "$EXTRA_E" ]]; then
  CMD+=(-e "$EXTRA_E")
fi

# Execute
"${CMD[@]}"