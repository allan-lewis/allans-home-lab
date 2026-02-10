#!/usr/bin/env bash
set -euo pipefail

# homelab-task-wrap: run a command and publish "last run" metrics for node_exporter textfile collector.
#
# Usage:
#   homelab-task-wrap <task> -- <command> [args...]
#
# Example:
#   homelab-task-wrap backup_runner -- /usr/local/bin/backup.sh --full
#
# Env overrides:
#   NODE_EXPORTER_TEXTFILE_DIR   default: /var/lib/node_exporter/textfile_collector

usage() {
  cat >&2 <<'EOF'
Usage:
  homelab-task-wrap <task> -- <command> [args...]

Env:
  NODE_EXPORTER_TEXTFILE_DIR  (default: /var/lib/node_exporter/textfile_collector)
EOF
  exit 2
}

[[ $# -ge 3 ]] || usage

TASK="$1"
shift

[[ "${1:-}" == "--" ]] || usage
shift

[[ $# -ge 1 ]] || usage

# Basic sanity: keep task as a stable slug so it’s safe in filenames and labels.
# Allow: letters, digits, underscore, dash, dot
if [[ ! "$TASK" =~ ^[A-Za-z0-9_.-]+$ ]]; then
  echo "ERROR: task must match ^[A-Za-z0-9_.-]+$ (got: '$TASK')" >&2
  exit 2
fi

TEXTDIR="${NODE_EXPORTER_TEXTFILE_DIR:-/var/lib/node_exporter/textfile_collector}"
OUT="${TEXTDIR}/homelab_task_${TASK}.prom"

# Ensure directory exists (fail loudly if not).
if [[ ! -d "$TEXTDIR" ]]; then
  echo "ERROR: textfile directory does not exist: $TEXTDIR" >&2
  exit 1
fi

# Temp file in the same directory so mv is atomic (same filesystem).
TMP="$(mktemp "${OUT}.tmp.XXXXXX")"
cleanup() { rm -f "$TMP" 2>/dev/null || true; }
trap cleanup EXIT

start_epoch="$(date +%s)"
start_ns="$(date +%s%N)"

rc=0
"$@" || rc=$?

end_ns="$(date +%s%N)"
end_epoch="$(date +%s)"

# Duration in seconds (float). Use awk to avoid bash integer overflow / division issues.
duration="$(awk -v s="$start_ns" -v e="$end_ns" 'BEGIN { printf "%.6f", (e-s)/1000000000 }')"

# Emit metrics. Always update run/rc/duration. Only update success on rc=0.
{
  echo "# HELP homelab_task_last_success_unix Unix timestamp of last successful run"
  echo "# TYPE homelab_task_last_success_unix gauge"
  if [[ "$rc" -eq 0 ]]; then
    echo "homelab_task_last_success_unix{task=\"${TASK}\"} ${end_epoch}"
  else
    # If there has never been a success, omitting the sample is fine; staleness alerts will fire.
    # If you prefer a sentinel value, change this to 0, but omission is usually better.
    :
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
} >"$TMP"

chmod 0644 "$TMP"
mv -f "$TMP" "$OUT"

# Success: keep file; cleanup trap will no-op since TMP moved.
trap - EXIT
exit "$rc"
