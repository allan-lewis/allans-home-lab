#!/usr/bin/env bash
set -euo pipefail

HOST="${1:?Usage: $0 <host> <apply|destroy> <template_manifest> <0|1>}"
MODE="${2:?Usage: $0 <host> <apply|destroy> <template_manifest> <0|1>}"
TEMPLATE_MANIFEST_PATH="${3:?Usage: $0 <host> <apply|destroy> <template_manifest> <0|1>}"
APPROVE="${4:?Usage: $0 <host> <apply|destroy> <template_manifest> <0|1>}"

TF_DIR="shared/terraform/roots/host_provisioning"


[[ -d "$TF_DIR" ]] || {
  echo "ERROR: Terraform directory does not exist: $TF_DIR" >&2
  exit 1
}

case "$MODE" in
apply | destroy) ;;
*)
  echo "ERROR: MODE must be 'apply' or 'destroy' (got: '$MODE')" >&2
  exit 2
  ;;
esac

case "$APPROVE" in
0 | 1) ;;
*)
  echo "ERROR: APPROVE must be 0 (plan) or 1 (execute) (got: '$APPROVE')" >&2
  exit 2
  ;;
esac

TEMPLATE_ABS_PATH="$(realpath "$TEMPLATE_MANIFEST_PATH")"
if [[ ! -f "${TEMPLATE_ABS_PATH}" ]]; then
  echo "ERROR: Template manifest not found: ${TEMPLATE_ABS_PATH}" >&2
  exit 1
fi

echo "==== Terraform host: $HOST ===="
echo "==== Terraform root module: $TF_DIR ===="
echo "==== Mode: $MODE ===="
echo "==== Approve: $APPROVE ===="
echo "==== Template: $TEMPLATE_ABS_PATH ===="

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

HOST_JSON_PATH="../../../../inventory/generated/terraform/${HOST}.json"

if [[ ! -f "${HOST_JSON_PATH}" ]]; then
  echo "ERROR: Host JSON not found: ${HOST_JSON_PATH}" >&2
  exit 1
fi

OS="$(jq -r --arg host "$HOST" '.hosts[$host].variant' "$HOST_JSON_PATH")"

if [[ "$OS" == "nixos" || "$OS" == "arch" ]]; then
  AGENT_ENABLED=true
else
  AGENT_ENABLED=false
fi

echo "==== Host JSON path: $HOST_JSON_PATH ===="
echo "==== Operating system: $OS ===="
echo "==== Guest agent enabled: $AGENT_ENABLED ===="

terraform init \
  -reconfigure \
  -input=false \
  -upgrade=false \
  -backend-config="bucket=gitops-homelab-orchestrator-tf" \
  -backend-config="key=hosts/$OS/$HOST/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  >/dev/null

case "${MODE}" in
apply)
  if [[ "${APPROVE:-0}" == "1" ]]; then
    echo "Applying Terraform changes (APPLY=1)"
    terraform apply -auto-approve \
      -var="agent_enabled=${AGENT_ENABLED}" \
      -var="hosts_json_path=${HOST_JSON_PATH}" \
      -var="template_manifest_path=${TEMPLATE_ABS_PATH}"
  else
    echo "Terraform plan only (no changes applied)."
    echo "Set APPLY=1 to actually apply."
    terraform plan \
      -var="agent_enabled=${AGENT_ENABLED}" \
      -var="hosts_json_path=${HOST_JSON_PATH}" \
      -var="template_manifest_path=${TEMPLATE_ABS_PATH}"
  fi
  ;;
destroy)
  if [[ "${APPROVE:-0}" == "1" ]]; then
    echo "Applying Terraform destroy (APPLY=1)"
    terraform apply -destroy -auto-approve \
      -var="agent_enabled=${AGENT_ENABLED}" \
      -var="hosts_json_path=${HOST_JSON_PATH}" \
      -var="template_manifest_path=${TEMPLATE_ABS_PATH}"
  else
    echo "Terraform destroy plan only (no changes applied)."
    echo "Set APPLY=1 to actually destroy."
    terraform plan -destroy \
      -var="agent_enabled=${AGENT_ENABLED}" \
      -var="hosts_json_path=${HOST_JSON_PATH}" \
      -var="template_manifest_path=${TEMPLATE_ABS_PATH}"
  fi
  ;;
esac
