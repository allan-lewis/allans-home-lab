#!/usr/bin/env bash
set -euo pipefail

HOST="${1:?Usage: $0 <host> <check|test|switch>}"
MODE="${2:?Usage: $0 <host> <check|test|switch>}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NIXOS_GITOPS_DIR="${ROOT_DIR}/infra/os/nixos-gitops"
HOST_DIR="${NIXOS_GITOPS_DIR}/hosts/${HOST}"
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

HOST_JSON_PATH="inventory/generated/terraform/${HOST}.json"
if [[ ! -f "${HOST_JSON_PATH}" ]]; then
  echo "ERROR: Host JSON not found: ${HOST_JSON_PATH}" >&2
  exit 1
fi

TARGET_HOST_IP="$(jq -r --arg host "$HOST" '.hosts[$host].terraform.ip' "$HOST_JSON_PATH")"

TARGET="lab@${TARGET_HOST_IP}"

echo "Identified target: ${TARGET}"

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

bootstrap_sops_age_key "${HOST_DIR}" "${TARGET}"

exec nix run nixpkgs#nixos-rebuild -- \
  "${MODE}" \
  --fast \
  --flake "${FLAKE_REF}" \
  --build-host "${TARGET}" \
  --target-host "${TARGET}" \
  --use-remote-sudo