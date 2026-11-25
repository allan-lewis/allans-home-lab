#!/usr/bin/env bash
set -euo pipefail

# Symmetrically encrypt or decrypt a file with GPG (AES256), using the
# passphrase in BACKUP_ENCRYPTION_KEY (supplied by Doppler).
#
# Usage: gpg-crypt.sh <encrypt|decrypt> <input> [output]
#
# Default output: encrypt -> <input>.gpg; decrypt -> <input> minus .gpg
# (or <input>.dec if it has no .gpg suffix). Existing files are never
# overwritten.

die() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  echo "Usage: $(basename "$0") <encrypt|decrypt> <input> [output]" >&2
  exit 2
}

[[ $# -ge 2 && $# -le 3 ]] || usage

MODE="$1"
INPUT="$2"
OUTPUT="${3:-}"

case "$MODE" in
  encrypt|decrypt) ;;
  *) usage ;;
esac

# ------------------------------------------------------------------------------
# Preconditions
# ------------------------------------------------------------------------------

command -v gpg >/dev/null 2>&1 || die "gpg not found on PATH (brew install gnupg)"

if [[ -z "${BACKUP_ENCRYPTION_KEY+x}" ]]; then
  die "BACKUP_ENCRYPTION_KEY is not set (run via 'doppler run --' or export it)"
fi
if [[ -z "${BACKUP_ENCRYPTION_KEY//[[:space:]]/}" ]]; then
  die "BACKUP_ENCRYPTION_KEY is set but empty"
fi

[[ -f "$INPUT" ]] || die "input file not found: $INPUT"
[[ -r "$INPUT" ]] || die "input file not readable: $INPUT"

if [[ -z "$OUTPUT" ]]; then
  if [[ "$MODE" == "encrypt" ]]; then
    OUTPUT="${INPUT}.gpg"
  elif [[ "$INPUT" == *.gpg ]]; then
    OUTPUT="${INPUT%.gpg}"
  else
    OUTPUT="${INPUT}.dec"
  fi
fi

[[ "$OUTPUT" != "$INPUT" ]] || die "output must differ from input"
[[ ! -e "$OUTPUT" ]] || die "output already exists, refusing to overwrite: $OUTPUT"

OUT_DIR="$(dirname "$OUTPUT")"
[[ -d "$OUT_DIR" ]] || die "output directory does not exist: $OUT_DIR"

# ------------------------------------------------------------------------------
# Encrypt / decrypt
# ------------------------------------------------------------------------------

# Write to a temp file alongside the output so a failure never leaves a
# partial file at the final path.
TMP_OUTPUT="$(mktemp "${OUT_DIR}/.gpg-crypt.XXXXXX")"
trap 'rm -f "$TMP_OUTPUT"' EXIT

GPG_ARGS=(
  --batch
  --yes
  --quiet
  --pinentry-mode loopback
  --passphrase-fd 3
  --no-symkey-cache
  --output "$TMP_OUTPUT"
)

if [[ "$MODE" == "encrypt" ]]; then
  GPG_ARGS+=(--symmetric --cipher-algo AES256)
else
  GPG_ARGS+=(--decrypt)
fi

# Pass the passphrase on fd 3 so it never appears in the process list.
if ! gpg "${GPG_ARGS[@]}" "$INPUT" 3< <(printf '%s' "$BACKUP_ENCRYPTION_KEY"); then
  die "gpg ${MODE} failed for: $INPUT"
fi

mv "$TMP_OUTPUT" "$OUTPUT"
trap - EXIT

echo "${MODE}ed: $INPUT -> $OUTPUT"
