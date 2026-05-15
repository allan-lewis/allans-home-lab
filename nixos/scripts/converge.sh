#!/usr/bin/env bash
set -euo pipefail

HOST="${1:?Usage: $0 <host> <check|test|switch>}"
MODE="${2:?Usage: $0 <host> <check|test|switch>}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NIXOS_GITOPS_DIR="${ROOT_DIR}/nixos"
HOST_DIR="${NIXOS_GITOPS_DIR}/hosts/${HOST}"
HOST_HARDWARE_CONFIG_PATH="${HOST_DIR}/hardware-configuration.nix"
VM_HARDWARE_TEMPLATE_PATH="${NIXOS_GITOPS_DIR}/template/config/hardware-configuration.nix"
FLAKE_REF="${NIXOS_GITOPS_DIR}#${HOST}"

if [[ ! -d "${HOST_DIR}" ]]; then
  echo "ERROR: Host directory not found: ${HOST_DIR}" >&2
  exit 1
fi

case "${MODE}" in
  check|test|switch) ;;
  *)
    echo "ERROR: MODE must be one of: check, test, switch" >&2
    exit 2
    ;;
esac

if [[ "${MODE}" == "check" ]]; then
  exec nix flake show "${HOST_DIR}"
fi

HOST_JSON_PATH=".build/inventory/terraform/${HOST}.json"
if [[ ! -f "${HOST_JSON_PATH}" ]]; then
  echo "ERROR: Host JSON not found: ${HOST_JSON_PATH}" >&2
  exit 1
fi

TARGET_HOST_IP="$(jq -r --arg host "$HOST" '.hosts[$host].terraform.ip' "$HOST_JSON_PATH")"
TARGET_KIND="$(jq -r --arg host "$HOST" '.hosts[$host].kind' "$HOST_JSON_PATH")"

if [[ -z "${TARGET_HOST_IP}" || "${TARGET_HOST_IP}" == "null" ]]; then
  echo "ERROR: Could not determine target host IP for ${HOST} from ${HOST_JSON_PATH}" >&2
  exit 1
fi

if [[ -z "${TARGET_KIND}" || "${TARGET_KIND}" == "null" ]]; then
  echo "ERROR: Could not determine target runtime kind for ${HOST} from ${HOST_JSON_PATH}" >&2
  exit 1
fi

TARGET="lab@${TARGET_HOST_IP}"

echo "Identified target: ${TARGET}"
echo "Identified runtime kind: ${TARGET_KIND}"

fetch_hardware_configuration() {
  local target="$1"
  local destination="$2"
  local kind="$3"

  if [[ "${kind}" == "vm" ]]; then
    echo "==> Checking local VM hardware-configuration.nix against template"

    if [[ ! -f "${VM_HARDWARE_TEMPLATE_PATH}" ]]; then
      echo "ERROR: VM hardware template not found: ${VM_HARDWARE_TEMPLATE_PATH}" >&2
      exit 1
    fi

    if [[ ! -f "${destination}" ]]; then
      cp "${VM_HARDWARE_TEMPLATE_PATH}" "${destination}"
      echo "==> Created missing VM hardware-configuration.nix from template: ${destination}"
      return 0
    fi

    if cmp -s "${destination}" "${VM_HARDWARE_TEMPLATE_PATH}"; then
      echo "==> VM hardware-configuration.nix already matches template"
      return 0
    fi

    cp "${VM_HARDWARE_TEMPLATE_PATH}" "${destination}"
    echo "==> Updated VM hardware-configuration.nix from template: ${destination}"
    return 0
  fi

  if [[ "${kind}" == "baremetal" ]]; then
    local tmp_file

    echo "==> Attempting to retrieve hardware-configuration.nix from ${target}"

    if ! ssh "${target}" 'test -f /etc/nixos/hardware-configuration.nix'; then
      echo "==> No hardware-configuration.nix found on remote host; skipping"
      return 0
    fi

    tmp_file="$(mktemp)"

    if ! ssh "${target}" 'sudo cat /etc/nixos/hardware-configuration.nix' > "${tmp_file}"; then
      echo "WARNING: Failed to fetch hardware-configuration.nix; continuing" >&2
      rm -f "${tmp_file}"
      return 0
    fi

    if [[ -f "${destination}" ]] && cmp -s "${tmp_file}" "${destination}"; then
      echo "==> No changes to hardware-configuration.nix"
      rm -f "${tmp_file}"
      return 0
    fi

    mv "${tmp_file}" "${destination}"
    echo "==> Updated ${destination}"
    return 0
  fi

  echo "WARNING: Unknown runtime kind ${kind}; skipping hardware-configuration.nix handling" >&2
}

bootstrap_sops_age_key() {
  local host_dir="$1"
  local target="$2"

  # Only bootstrap if the host appears to use sops-nix.
  # if ! grep -Rqs 'sops-nix\.nixosModules\.sops\|sops\.age\.keyFile\|sops\.secrets\.' "${host_dir}"; then
  #   echo "==> No sops-nix usage detected for ${HOST}; skipping bootstrap"
  #   return 0
  # fi

  if [[ -z "${SOPS_AGE_KEY:-}" ]]; then
    echo "ERROR: sops-nix appears configured for ${HOST}, but SOPS_AGE_KEY is not set." >&2
    echo "Run this script via Doppler so SOPS_AGE_KEY is available." >&2
    exit 5
  fi

  echo "==> Bootstrapping shared SOPS age key to ${target}"

  ssh "${target}" 'sudo install -d -m 0700 -o root -g root /var/lib/sops-nix'

  # Write exact multiline key contents with root ownership and 0600 perms.
  ssh "${target}" 'sudo tee /var/lib/sops-nix/key.txt >/dev/null && sudo chown root:root /var/lib/sops-nix/key.txt && sudo chmod 0600 /var/lib/sops-nix/key.txt' <<< "${SOPS_AGE_KEY}"
}

fetch_hardware_configuration "${TARGET}" "${HOST_HARDWARE_CONFIG_PATH}" "${TARGET_KIND}"
bootstrap_sops_age_key "${HOST_DIR}" "${TARGET}"

exec nix run nixpkgs#nixos-rebuild -- \
  "${MODE}" \
  --fast \
  --flake "${FLAKE_REF}" \
  --build-host "${TARGET}" \
  --target-host "${TARGET}" \
  --use-remote-sudo
