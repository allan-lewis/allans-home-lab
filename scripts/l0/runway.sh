#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root relative to this script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

mkdir -p artifacts/l0
ansible-playbook ansible/l0/runway.yaml
