#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root relative to this script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

ansible-playbook -i ansible/inventory/ ansible/l4/nixos.yaml
