#!/usr/bin/env bash
set -euo pipefail

PLAYBOOK="${1:?Usage: $0 <playbook> [tags] [limit] [extra_e]}"
TAGS="${2:-}"
LIMIT="${3:-}"
EXTRA_E="${4:-}"   # e.g. 'foo=bar baz=qux' OR '@vars.yml' OR '{"a":1}'

# Resolve repo root relative to this script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

# Build ansible command safely as an array
CMD=(
  ansible-playbook
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

cd linux/ansible

# Execute
"${CMD[@]}"