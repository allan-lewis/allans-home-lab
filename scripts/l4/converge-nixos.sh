#!/usr/bin/env bash
set -euo pipefail

GROUP="${1:?Usage: $0 <group> <layer>}"

# Resolve repo root relative to this script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

ansible-playbook -i ansible/inventory/ -e converge_group="${GROUP}" ansible/l4/nixos.yaml
