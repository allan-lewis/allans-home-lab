#!/usr/bin/env bash
set -euo pipefail

###
# init-upgrade.sh
#
# Upgrades provider/module versions for the host_provisioning Terraform root
# (terraform init -upgrade) without touching any backend or state - every
# host shares this one root module, so there's nothing host-specific to
# upgrade. Never plans or applies.
###

TF_DIR="shared/terraform/roots/host_provisioning"

[[ -d "$TF_DIR" ]] || {
  echo "ERROR: Terraform directory does not exist: $TF_DIR" >&2
  exit 1
}

echo "==== Terraform root module: $TF_DIR ===="
echo "==== Mode: init -upgrade -backend=false (no plan/apply) ===="

cd "${TF_DIR}"

terraform init \
  -upgrade \
  -backend=false \
  -input=false

echo
echo "==== Done. ===="
echo "If .terraform.lock.hcl changed, commit it so provision.sh's -upgrade=false stays reproducible."
