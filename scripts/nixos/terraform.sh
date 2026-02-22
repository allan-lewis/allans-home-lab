#!/usr/bin/env bash
set -euo pipefail

PERSONA="${1:?Usage: $0 <persona> <apply|destroy> <0|1>}"
MODE="${2:?Usage: $0 <persona> <apply|destroy> <0|1>}"
APPROVE="${3:?Usage: $0 <persona> <apply|destroy> <0|1>}"

TF_DIR="terraform/nixos/$PERSONA"

[[ -d "$TF_DIR" ]] || {
  echo "ERROR: Terraform directory does not exist: $TF_DIR" >&2
  exit 1
}

case "$MODE" in
  apply|destroy) ;;
  *)
    echo "ERROR: MODE must be 'apply' or 'destroy' (got: '$MODE')" >&2
    exit 2
    ;;
esac

case "$APPROVE" in
  0|1) ;;
  *)
    echo "ERROR: APPROVE must be 0 (plan) or 1 (execute) (got: '$APPROVE')" >&2
    exit 2
    ;;
esac

echo "==== Terraform persona: $PERSONA ===="
echo "==== Directory: $TF_DIR ===="
echo "==== Mode: $MODE ===="
echo "==== Approve: $APPROVE ===="

# --- Environment validation ---------------------------------------------------

: "${PVE_ACCESS_HOST:?Missing PVE_ACCESS_HOST}"
: "${PM_TOKEN_ID:?Missing PM_TOKEN_ID}"
: "${PM_TOKEN_SECRET:?Missing PM_TOKEN_SECRET}"
: "${TF_VAR_PROXMOX_VM_PUBLIC_KEY:?Missing TF_VAR_PROXMOX_VM_PUBLIC_KEY}"

# --- Setup Terraform variables -----------------------------------------------

export TF_VAR_pve_access_host="${PVE_ACCESS_HOST}"
export TF_VAR_pm_token_id="${PM_TOKEN_ID}"
export TF_VAR_pm_token_secret="${PM_TOKEN_SECRET}"
export TF_VAR_proxmox_vm_public_key="${TF_VAR_PROXMOX_VM_PUBLIC_KEY}"

# --- Run Terraform ------------------------------------------------------------

cd "${TF_DIR}"

terraform init -input=false -upgrade=false >/dev/null

case "${MODE}" in
  apply)
    if [[ "${APPROVE:-0}" == "1" ]]; then
      echo "Applying Terraform changes (APPLY=1)"
      terraform apply -auto-approve
    else
      echo "Terraform plan only (no changes applied)."
      echo "Set APPLY=1 to actually apply."
      terraform plan
    fi
    ;;
  destroy)
    if [[ "${APPROVE:-0}" == "1" ]]; then
      echo "Applying Terraform destroy (APPLY=1)"
      terraform apply -destroy -auto-approve
    else
      echo "Terraform destroy plan only (no changes applied)."
      echo "Set APPLY=1 to actually destroy."
      terraform plan -destroy
    fi
    ;;
esac
