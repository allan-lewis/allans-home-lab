#!/usr/bin/env bash
set -euo pipefail

HOST="${1:?Usage: $0 <host> <check|test|switch>}"
MODE="${2:?Usage: $0 <host> <check|test|switch>}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NIXOS_GITOPS_DIR="${ROOT_DIR}/infra/os/nixos-gitops"
HOST_DIR="${NIXOS_GITOPS_DIR}/${HOST}"
TARGET_HOST_FILE="${HOST_DIR}/target-host"
FLAKE_REF="${HOST_DIR}#${HOST}"

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

if [[ ! -f "${TARGET_HOST_FILE}" ]]; then
  echo "ERROR: target-host file not found: ${TARGET_HOST_FILE}" >&2
  exit 3
fi

TARGET="$(<"${TARGET_HOST_FILE}")"

if [[ -z "${TARGET}" ]]; then
  echo "ERROR: target-host file is empty: ${TARGET_HOST_FILE}" >&2
  exit 4
fi

bootstrap_sops_age_key() {
  local host_dir="$1"
  local target="$2"

  # Only bootstrap if the host appears to use sops-nix.
  if ! grep -Rqs 'sops-nix\.nixosModules\.sops\|sops\.age\.keyFile\|sops\.secrets\.' "${host_dir}"; then
    echo "==> No sops-nix usage detected for ${HOST}; skipping bootstrap"
    return 0
  fi

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