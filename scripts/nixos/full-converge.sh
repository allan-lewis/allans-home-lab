#!/usr/bin/env bash
set -euo pipefail

GROUP="${1:?Usage: $0 <group> <tags> <limit>}"
TAGS="$2"
LIMIT="$3"

# Resolve repo root relative to this script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

# TODO: Add in support for tags/limit

ansible-playbook -i ansible/inventory/ -e converge_group="${GROUP}" ansible/nixos/converge.yaml
