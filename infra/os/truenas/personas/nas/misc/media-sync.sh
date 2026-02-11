#!/usr/bin/env bash
# media-sync: one-off rsync + node_exporter textfile metrics (no external wrapper)

set -euo pipefail

TASK="media_sync"
TEXTDIR="/var/lib/node_exporter/textfile_collector"
OUT="${TEXTDIR}/homelab_task_media_sync.prom"

# ---- timing helpers ----
start_ns="$(date +%s%N)"
start_epoch="$(date +%s)"
rc=0

# Ensure collector dir exists
if [[ ! -d "$TEXTDIR" ]]; then
  echo "ERROR: textfile collector dir missing: $TEXTDIR" >&2
  exit 1
fi

# Temp file in same dir so mv is atomic
TMP="$(mktemp "${OUT}.tmp.XXXXXX")"
cleanup() { rm -f "$TMP" 2>/dev/null || true; }
trap cleanup EXIT

# ---- work ----
# If either rsync fails, we want rc != 0 but still emit metrics. So:
set +e
rsync -av /mnt/pool1/media-acquisition/movies/ /mnt/pool1/media-library/movies/
rc=$((rc != 0 ? rc : $?))

rsync -av /mnt/pool1/media-acquisition/tv/ /mnt/pool1/media-library/shows/
rc2=$?
if [[ "$rc" -eq 0 ]]; then rc="$rc2"; fi
set -e

# ---- metrics ----
end_ns="$(date +%s%N)"
end_epoch="$(date +%s)"
duration="$(awk -v s="$start_ns" -v e="$end_ns" 'BEGIN { printf "%.6f", (e-s)/1000000000 }')"

{
  # Only emit last_success on success, matching the wrapper behavior.
  echo "# HELP homelab_task_last_success_unix Unix timestamp of last successful run"
  echo "# TYPE homelab_task_last_success_unix gauge"
  if [[ "$rc" -eq 0 ]]; then
    echo "homelab_task_last_success_unix{task=\"${TASK}\"} ${end_epoch}"
  fi

  echo "# HELP homelab_task_last_run_unix Unix timestamp of last run (success or failure)"
  echo "# TYPE homelab_task_last_run_unix gauge"
  echo "homelab_task_last_run_unix{task=\"${TASK}\"} ${end_epoch}"

  echo "# HELP homelab_task_last_exit_code Last exit code (0=success)"
  echo "# TYPE homelab_task_last_exit_code gauge"
  echo "homelab_task_last_exit_code{task=\"${TASK}\"} ${rc}"

  echo "# HELP homelab_task_last_duration_seconds Duration of last run in seconds"
  echo "# TYPE homelab_task_last_duration_seconds gauge"
  echo "homelab_task_last_duration_seconds{task=\"${TASK}\"} ${duration}"
} >"${TMP}"

chmod 0644 "${TMP}"
mv -f "${TMP}" "${OUT}"
trap - EXIT

exit "$rc"
