#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Style
# ------------------------------------------------------------------------------

if [[ -t 1 ]]; then
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  RESET=$'\033[0m'
  RED=$'\033[31m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  BLUE=$'\033[34m'
  CYAN=$'\033[36m'
  MAGENTA=$'\033[35m'
else
  BOLD=""
  DIM=""
  RESET=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  CYAN=""
  MAGENTA=""
fi

# ------------------------------------------------------------------------------
# Global state
# ------------------------------------------------------------------------------

ARTIFACTS_DIR="${ARTIFACTS_DIR:-./.build/runway}"

RUNWAY_STATUS="INIT"
FAIL_REASONS=()
WARN_REASONS=()

HOST_STRIPPED=""
AUTH_HEADER=""

# ------------------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------------------

log_section() { printf "\n${BOLD}${CYAN}==> %s${RESET}\n" "$1"; }
log_step()    { printf "${BLUE} ->${RESET} %s\n" "$1"; }
log_info()    { printf "${DIM}    %s${RESET}\n" "$1"; }
log_pass()    { printf "${GREEN}✔ PASS${RESET} %s\n" "$1"; }
log_fail()    { printf "${RED}✖ FAIL${RESET} %s\n" "$1"; }
log_warn()    { printf "${YELLOW}⚠ WARN${RESET} %s\n" "$1"; }

add_fail() {
  local msg="$1"
  FAIL_REASONS+=("$msg")
  RUNWAY_STATUS="FAIL"
  log_fail "$msg"
}

add_warn() {
  local msg="$1"
  WARN_REASONS+=("$msg")
  if [[ "$RUNWAY_STATUS" == "INIT" || "$RUNWAY_STATUS" == "OK" ]]; then
    RUNWAY_STATUS="WARN"
  fi
  log_warn "$msg"
}

# ------------------------------------------------------------------------------
# Pre-task equivalents
# ------------------------------------------------------------------------------

ensure_artifacts_dir() {
  mkdir -p "$ARTIFACTS_DIR"
  chmod 0755 "$ARTIFACTS_DIR"
  log_pass "Artifacts directory ready: $ARTIFACTS_DIR"
}

seed_defaults() {
  FAIL_REASONS=()
  WARN_REASONS=()
  RUNWAY_STATUS="INIT"

  HOST_STRIPPED="$(printf '%s' "${PVE_ACCESS_HOST:-}" | sed -E 's#^https?://##')"
  AUTH_HEADER="PVEAPIToken=${PM_TOKEN_ID:-}=${PM_TOKEN_SECRET:-}"
  PVE_BRIDGE="${PVE_BRIDGE:-vmbr0}"
  PVE_STORAGE_ISO="${PVE_STORAGE_ISO:-local}"
  L0_MIN_FREE_GIB_ISO="${L0_MIN_FREE_GIB_ISO:-4}"
  L0_MIN_FREE_PCT_VM="${L0_MIN_FREE_PCT_VM:-10}"

  log_pass "Initialized runway state"
  log_info "Host (stripped): ${HOST_STRIPPED:-<empty>}"
  log_info "Auth header prepared: yes"
}

validate_required_inputs() {
  local missing=()

  [[ -n "${PVE_ACCESS_HOST:-}" ]] || missing+=("PVE_ACCESS_HOST")
  [[ -n "${PM_TOKEN_ID:-}" ]] || missing+=("PM_TOKEN_ID")
  [[ -n "${PM_TOKEN_SECRET:-}" ]] || missing+=("PM_TOKEN_SECRET")
  [[ -n "${PVE_NODE:-}" ]] || missing+=("PVE_NODE")
  [[ -n "${PVE_STORAGE_VM:-}" ]] || missing+=("PVE_STORAGE_VM")
  [[ -n "${PVE_STORAGE_ISO:-}" ]] || missing+=("PVE_STORAGE_ISO")

  if [[ "${#missing[@]}" -eq 0 ]]; then
    log_pass "Required inputs are populated"
    return 0
  fi

  log_fail "Missing required inputs: $(IFS=,; echo "${missing[*]}")"
  return 1
}

# ------------------------------------------------------------------------------
# Role equivalents
# ------------------------------------------------------------------------------

runway_api() {
  log_section "API / auth"

  if [[ -z "${HOST_STRIPPED:-}" || -z "${PM_TOKEN_ID:-}" || -z "${PM_TOKEN_SECRET:-}" ]]; then
    add_fail "API unreachable or auth failed"
    log_info "Skipped API check because required auth inputs were missing"
    return 0
  fi

  local url
  local response_file
  local body_file
  local http_code
  local curl_rc

  url="https://${HOST_STRIPPED}/api2/json/version"
  response_file="${ARTIFACTS_DIR}/pve_version.json"
  body_file="${ARTIFACTS_DIR}/pve_version.body"

  log_step "GET ${url}"
  log_info "Writing response artifact to ${response_file}"

  set +e
  http_code="$(
    curl \
      --silent \
      --show-error \
      --location \
      --connect-timeout 5 \
      --max-time 15 \
      --output "$body_file" \
      --write-out '%{http_code}' \
      --header "Authorization: ${AUTH_HEADER}" \
      --header 'Accept: application/json' \
      --fail-with-body \
      "$url"
  )"
  curl_rc=$?
  set -e

  if [[ -s "$body_file" ]]; then
    cp "$body_file" "$response_file"
    chmod 0644 "$response_file"
  else
    printf '{}\n' > "$response_file"
    chmod 0644 "$response_file"
  fi

  if [[ "$curl_rc" -eq 0 && "$http_code" == "200" ]]; then
    log_pass "Proxmox API reachable and token auth succeeded"
    return 0
  fi

  add_fail "API unreachable or auth failed"
  log_info "curl exit code: ${curl_rc}"
  log_info "HTTP status: ${http_code:-<none>}"

  return 0
}

runway_node() {
  log_section "Node status"

  local url
  local response_file
  local body_file
  local http_code
  local curl_rc
  local node_status

  url="https://${HOST_STRIPPED}/api2/json/nodes"
  response_file="${ARTIFACTS_DIR}/nodes.json"
  body_file="${ARTIFACTS_DIR}/nodes.body"

  log_step "GET ${url}"
  log_info "Writing response artifact to ${response_file}"

  set +e
  http_code="$(
    curl \
      --silent \
      --show-error \
      --location \
      --connect-timeout 5 \
      --max-time 15 \
      --output "$body_file" \
      --write-out '%{http_code}' \
      --header "Authorization: ${AUTH_HEADER}" \
      --header 'Accept: application/json' \
      --fail-with-body \
      "$url"
  )"
  curl_rc=$?
  set -e

  if [[ -s "$body_file" ]]; then
    cp "$body_file" "$response_file"
    chmod 0644 "$response_file"
  else
    printf '{}\n' > "$response_file"
    chmod 0644 "$response_file"
  fi

  rm -f "$body_file"

  if [[ "$curl_rc" -ne 0 || "$http_code" != "200" ]]; then
    add_fail "Node ${PVE_NODE} not found"
    log_info "Unable to retrieve node list"
    log_info "curl exit code: ${curl_rc}"
    log_info "HTTP status: ${http_code:-<none>}"
    return 0
  fi

  node_status="$(
    python3 - "$response_file" "$PVE_NODE" <<'PY'
import json
import sys

path = sys.argv[1]
target = sys.argv[2]

try:
    with open(path, "r", encoding="utf-8") as f:
        payload = json.load(f)
except Exception:
    print("missing")
    raise SystemExit(0)

for item in payload.get("data", []):
    if item.get("node") == target:
        print(item.get("status", "missing"))
        raise SystemExit(0)

print("missing")
PY
  )"

  case "$node_status" in
    online)
      log_pass "Node ${PVE_NODE} is online"
      ;;
    missing)
      add_fail "Node ${PVE_NODE} not found"
      ;;
    *)
      add_fail "Node ${PVE_NODE} not online (status=${node_status})"
      ;;
  esac

  return 0
}

runway_network() {
  log_section "Network / bridge"

  local url
  local response_file
  local body_file
  local http_code
  local curl_rc
  local bridge_type
  local bridge_active

  url="https://${HOST_STRIPPED}/api2/json/nodes/${PVE_NODE}/network"
  response_file="${ARTIFACTS_DIR}/network_${PVE_NODE}.json"
  body_file="${ARTIFACTS_DIR}/network_${PVE_NODE}.body"

  log_step "GET ${url}"
  log_info "Writing response artifact to ${response_file}"

  set +e
  http_code="$(
    curl \
      --silent \
      --show-error \
      --location \
      --connect-timeout 5 \
      --max-time 15 \
      --output "$body_file" \
      --write-out '%{http_code}' \
      --header "Authorization: ${AUTH_HEADER}" \
      --header 'Accept: application/json' \
      --fail-with-body \
      "$url"
  )"
  curl_rc=$?
  set -e

  if [[ -s "$body_file" ]]; then
    cp "$body_file" "$response_file"
    chmod 0644 "$response_file"
  else
    printf '{}\n' > "$response_file"
    chmod 0644 "$response_file"
  fi

  rm -f "$body_file"

  if [[ "$curl_rc" -ne 0 || "$http_code" != "200" ]]; then
    add_fail "Bridge ${PVE_BRIDGE} not found on node ${PVE_NODE}"
    log_info "Unable to retrieve network config for node ${PVE_NODE}"
    log_info "curl exit code: ${curl_rc}"
    log_info "HTTP status: ${http_code:-<none>}"
    return 0
  fi

  read -r bridge_type bridge_active < <(
    python3 - "$response_file" "${PVE_BRIDGE}" <<'PY'
import json
import sys

path = sys.argv[1]
target = sys.argv[2]

try:
    with open(path, "r", encoding="utf-8") as f:
        payload = json.load(f)
except Exception:
    print("missing 0")
    raise SystemExit(0)

for item in payload.get("data", []):
    if item.get("iface") == target:
        print(f"{item.get('type', 'missing')} {item.get('active', '0')}")
        raise SystemExit(0)

print("missing 0")
PY
  )

  if [[ "$bridge_type" != "bridge" ]]; then
    add_fail "Bridge ${PVE_BRIDGE} not found on node ${PVE_NODE}"
    return 0
  fi

  log_pass "Bridge ${PVE_BRIDGE} exists on node ${PVE_NODE}"

  if [[ "${bridge_active}" != "1" ]]; then
    add_warn "Bridge ${PVE_BRIDGE} exists but is not active"
    return 0
  fi

  log_pass "Bridge ${PVE_BRIDGE} is active"
  return 0
}

runway_storage() {
  log_section "Storage thresholds"

  local iso_url
  local iso_response_file
  local iso_body_file
  local iso_http_code
  local iso_curl_rc

  local vm_url
  local vm_response_file
  local vm_body_file
  local vm_http_code
  local vm_curl_rc

  local iso_free_gib
  local vm_free_pct

  iso_url="https://${HOST_STRIPPED}/api2/json/nodes/${PVE_NODE}/storage/${PVE_STORAGE_ISO}/status"
  iso_response_file="${ARTIFACTS_DIR}/storage_${PVE_STORAGE_ISO}.json"
  iso_body_file="${ARTIFACTS_DIR}/storage_${PVE_STORAGE_ISO}.body"

  vm_url="https://${HOST_STRIPPED}/api2/json/nodes/${PVE_NODE}/storage/${PVE_STORAGE_VM}/status"
  vm_response_file="${ARTIFACTS_DIR}/storage_${PVE_STORAGE_VM}.json"
  vm_body_file="${ARTIFACTS_DIR}/storage_${PVE_STORAGE_VM}.body"

  log_step "GET ${iso_url}"
  log_info "Writing response artifact to ${iso_response_file}"

  set +e
  iso_http_code="$(
    curl \
      --silent \
      --show-error \
      --location \
      --connect-timeout 5 \
      --max-time 15 \
      --output "$iso_body_file" \
      --write-out '%{http_code}' \
      --header "Authorization: ${AUTH_HEADER}" \
      --header 'Accept: application/json' \
      --fail-with-body \
      "$iso_url"
  )"
  iso_curl_rc=$?
  set -e

  if [[ -s "$iso_body_file" ]]; then
    cp "$iso_body_file" "$iso_response_file"
    chmod 0644 "$iso_response_file"
  else
    printf '{}\n' > "$iso_response_file"
    chmod 0644 "$iso_response_file"
  fi

  rm -f "$iso_body_file"

  log_step "GET ${vm_url}"
  log_info "Writing response artifact to ${vm_response_file}"

  set +e
  vm_http_code="$(
    curl \
      --silent \
      --show-error \
      --location \
      --connect-timeout 5 \
      --max-time 15 \
      --output "$vm_body_file" \
      --write-out '%{http_code}' \
      --header "Authorization: ${AUTH_HEADER}" \
      --header 'Accept: application/json' \
      --fail-with-body \
      "$vm_url"
  )"
  vm_curl_rc=$?
  set -e

  if [[ -s "$vm_body_file" ]]; then
    cp "$vm_body_file" "$vm_response_file"
    chmod 0644 "$vm_response_file"
  else
    printf '{}\n' > "$vm_response_file"
    chmod 0644 "$vm_response_file"
  fi

  rm -f "$vm_body_file"

  iso_free_gib="$(
    python3 - "$iso_response_file" <<'PY'
import json
import sys

try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        payload = json.load(f)
    avail = int(payload.get("data", {}).get("avail", 0) or 0)
except Exception:
    avail = 0

print(round(avail / (1024 ** 3), 2))
PY
  )"

  vm_free_pct="$(
    python3 - "$vm_response_file" <<'PY'
import json
import sys

try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        payload = json.load(f)
    data = payload.get("data", {})
    avail = float(data.get("avail", 0) or 0)
    total = float(data.get("total", 1) or 1)
    if total <= 0:
        total = 1
except Exception:
    avail = 0.0
    total = 1.0

print(round((avail / total) * 100.0, 2))
PY
  )"

  log_info "ISO store ${PVE_STORAGE_ISO} free: ${iso_free_gib} GiB"
  log_info "VM store ${PVE_STORAGE_VM} free: ${vm_free_pct}%"

  if [[ "$iso_curl_rc" -ne 0 || "$iso_http_code" != "200" ]]; then
    add_fail "Insufficient free space on ${PVE_STORAGE_ISO} (ISO store: ${iso_free_gib} GiB)"
    log_info "Unable to retrieve ISO storage status cleanly"
    log_info "curl exit code: ${iso_curl_rc}"
    log_info "HTTP status: ${iso_http_code:-<none>}"
    return 0
  fi

  if [[ "$vm_curl_rc" -ne 0 || "$vm_http_code" != "200" ]]; then
    add_fail "Insufficient free space on ${PVE_STORAGE_VM} (VM store free: ${vm_free_pct}%)"
    log_info "Unable to retrieve VM storage status cleanly"
    log_info "curl exit code: ${vm_curl_rc}"
    log_info "HTTP status: ${vm_http_code:-<none>}"
    return 0
  fi

  if python3 - <<PY
iso_free_gib = float("${iso_free_gib}")
threshold = float("${L0_MIN_FREE_GIB_ISO}")
raise SystemExit(0 if iso_free_gib < threshold else 1)
PY
  then
    add_fail "Insufficient free space on ${PVE_STORAGE_ISO} (ISO store: ${iso_free_gib} GiB)"
    return 0
  fi

  if python3 - <<PY
vm_free_pct = float("${vm_free_pct}")
threshold = float("${L0_MIN_FREE_PCT_VM}")
raise SystemExit(0 if vm_free_pct < threshold else 1)
PY
  then
    add_fail "Insufficient free space on ${PVE_STORAGE_VM} (VM store free: ${vm_free_pct}%)"
    return 0
  fi

  log_pass "Storage thresholds satisfied"
  return 0
}

runway_manifest() {
  log_section "Manifest / summary"

  local manifest_file
  local failures_json
  local runway_status
  local fail_count=0

  manifest_file="${ARTIFACTS_DIR}/runway_manifest.json"

  if declare -p FAIL_REASONS >/dev/null 2>&1; then
    fail_count=${#FAIL_REASONS[@]}
  fi

  if (( fail_count > 0 )); then
    runway_status="FAIL"
  else
    runway_status="OK"
  fi

  if declare -p FAIL_REASONS >/dev/null 2>&1 && (( ${#FAIL_REASONS[@]} > 0 )); then
    failures_json="$(
      printf '%s\n' "${FAIL_REASONS[@]}" | python3 - <<'PY'
import json
import sys

items = [line.rstrip("\n") for line in sys.stdin if line.rstrip("\n")]
print(json.dumps(items))
PY
    )"
  else
    failures_json='[]'
  fi

  python3 - "$manifest_file" <<PY
import json

manifest = {
    "runway_status": "${runway_status}",
    "proxmox": {
        "host": "${HOST_STRIPPED}",
        "node": "${PVE_NODE}",
    },
    "network": {
        "bridge": "${PVE_BRIDGE}",
    },
    "storage": {
        "iso": {
            "name": "${PVE_STORAGE_ISO}",
            "free_gib": float("${ISO_FREE_GIB:-0.0}"),
        },
        "vm": {
            "name": "${PVE_STORAGE_VM}",
            "free_pct": float("${VM_FREE_PCT:-0.0}"),
        },
    },
    "notes": "L0 performed read-only checks.",
    "failures": ${failures_json},
}

with open("${manifest_file}", "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)
    f.write("\\n")
PY

  chmod 0644 "$manifest_file"

  RUNWAY_STATUS="$runway_status"

  log_pass "Wrote runway manifest: ${manifest_file}"
}

# ------------------------------------------------------------------------------
# Final summary
# ------------------------------------------------------------------------------

print_summary() {
  log_section "Final status"

  local fail_count=0
  local warn_count=0
  local reason

  if declare -p FAIL_REASONS >/dev/null 2>&1; then
    fail_count=${#FAIL_REASONS[@]}
  fi

  if declare -p WARN_REASONS >/dev/null 2>&1; then
    warn_count=${#WARN_REASONS[@]}
  fi

  printf "\n"

  if (( fail_count == 0 && warn_count == 0 )); then
    printf "${GREEN}${BOLD}"
    printf "╔══════════════════════════════════════════════╗\n"
    printf "║           RUNWAY CLEARED FOR TAKEOFF         ║\n"
    printf "╚══════════════════════════════════════════════╝\n"
    printf "${RESET}"

  elif (( fail_count == 0 && warn_count > 0 )); then
    printf "${YELLOW}${BOLD}"
    printf "╔══════════════════════════════════════════════╗\n"
    printf "║        RUNWAY CLEAR WITH ADVISORIES          ║\n"
    printf "╚══════════════════════════════════════════════╝\n"
    printf "${RESET}"

  else
    printf "${RED}${BOLD}"
    printf "╔══════════════════════════════════════════════╗\n"
    printf "║            RUNWAY NOT CLEARED                ║\n"
    printf "╚══════════════════════════════════════════════╝\n"
    printf "${RESET}"
  fi

  printf "\n"
  printf "  ${GREEN}PASS${RESET}  Checks passed\n"
  printf "  ${YELLOW}WARN${RESET}  %d issue(s)\n" "$warn_count"
  printf "  ${RED}FAIL${RESET}  %d issue(s)\n" "$fail_count"

  if (( fail_count > 0 )); then
    printf "\n${RED}${BOLD}Failures:${RESET}\n"
    for reason in "${FAIL_REASONS[@]}"; do
      printf "  ✖ %s\n" "$reason"
    done
  fi

  if (( warn_count > 0 )); then
    printf "\n${YELLOW}${BOLD}Warnings:${RESET}\n"
    for reason in "${WARN_REASONS[@]}"; do
      printf "  ⚠ %s\n" "$reason"
    done
  fi

  printf "\n"

  if (( fail_count > 0 )); then
    exit 1
  fi
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

main() {
  printf "${BOLD}${MAGENTA}L0 Proxmox Runway${RESET}\n"

  log_section "Pre-tasks"
  ensure_artifacts_dir
  seed_defaults

  log_section "Input validation"
  validate_required_inputs

  runway_api
  runway_node
  runway_network
  runway_storage
  runway_manifest

  print_summary
}

main "$@"