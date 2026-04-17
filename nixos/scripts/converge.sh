#!/usr/bin/env bash
set -euo pipefail

HOST="${1:?Usage: $0 <host> <check|test|switch>}"
MODE="${2:?Usage: $0 <host> <check|test|switch>}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NIXOS_GITOPS_DIR="${ROOT_DIR}/nixos"
HOST_DIR="${NIXOS_GITOPS_DIR}/hosts/${HOST}"
HOST_HARDWARE_CONFIG_PATH="${HOST_DIR}/hardware-configuration.nix"
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

if [[ -z "${TARGET_HOST_IP}" || "${TARGET_HOST_IP}" == "null" ]]; then
  echo "ERROR: Could not determine target host IP for ${HOST} from ${HOST_JSON_PATH}" >&2
  exit 1
fi

TARGET="lab@${TARGET_HOST_IP}"

echo "Identified target: ${TARGET}"

fetch_hardware_configuration() {
  local target="$1"
  local destination="$2"
  local tmp_file

  echo "==> Attempting to retrieve hardware-configuration.nix from ${target}"

  # Check if file exists on remote
  if ! ssh "${target}" 'test -f /etc/nixos/hardware-configuration.nix'; then
    echo "==> No hardware-configuration.nix found on remote host; skipping"
    return 0
  fi

  tmp_file="$(mktemp)"

  # Attempt fetch (non-fatal)
  if ssh "${target}" 'sudo cat /etc/nixos/hardware-configuration.nix' > "${tmp_file}"; then
    # If file already exists locally and is identical, skip update
    if [[ -f "${destination}" ]] && cmp -s "${tmp_file}" "${destination}"; then
      echo "==> No changes to hardware-configuration.nix"
      rm -f "${tmp_file}"
      return 0
    fi

    mv "${tmp_file}" "${destination}"
    echo "==> Updated ${destination}"
  else
    echo "WARNING: Failed to fetch hardware-configuration.nix; continuing" >&2
    rm -f "${tmp_file}"
  fi
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

fetch_hardware_configuration "${TARGET}" "${HOST_HARDWARE_CONFIG_PATH}"
bootstrap_sops_age_key "${HOST_DIR}" "${TARGET}"

exec nix run nixpkgs#nixos-rebuild -- \
  "${MODE}" \
  --fast \
  --flake "${FLAKE_REF}" \
  --build-host "${TARGET}" \
  --target-host "${TARGET}" \
  --use-remote-sudo