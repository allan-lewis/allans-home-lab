#!/usr/bin/env bash
set -euo pipefail

GROUP="${1:?Usage: $0 <group> [tags] [limit]}"
TAGS="${2:-}"
LIMIT="${3:-}"

# Resolve repo root relative to this script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

# Build ansible command safely as an array
CMD=(
  ansible-playbook
  -i ansible/inventory/
  -e converge_group="${GROUP}"
  ansible/nixos/converge.yaml
)

# Add tags if provided
if [[ -n "$TAGS" ]]; then
  CMD+=(--tags "$TAGS")
fi

# Add limit if provided
if [[ -n "$LIMIT" ]]; then
  CMD+=(--limit "$LIMIT")
fi

# Execute
"${CMD[@]}"
