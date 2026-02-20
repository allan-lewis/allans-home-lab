{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.backupRunner;

  py = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);

  runnerScript = pkgs.writeShellScript "homelab-backup-runner" ''
    set -Eeuo pipefail

    CONFIG=${lib.escapeShellArg cfg.configPath}

    HOME_DIR="''${HOME:-/tmp}"
    LOGFILE="$HOME_DIR/backup-runner.log"
    KNOWN_HOSTS="$HOME_DIR/known_hosts"

    mkdir -p "$HOME_DIR"
    touch "$LOGFILE" "$KNOWN_HOSTS"
    chmod 0644 "$LOGFILE" || true
    chmod 0600 "$KNOWN_HOSTS" || true

    # Log to journal + file
    exec > >(tee -a "$LOGFILE") 2>&1

    timestamp() { date +"%Y-%m-%d %H:%M:%S%z"; }
    log() { echo "$(timestamp) | $*"; }
    die() { log "FATAL  | $*"; exit 1; }

    on_err() {
      rc=$?
      log "FATAL  | backup runner failed (exit=$rc)"
      exit "$rc"
    }
    trap on_err ERR

    [[ -f "$CONFIG" ]] || die "Config missing: $CONFIG"

    # ---- YAML -> JSON (fail hard on any parse error) ----
    cfg_json="$(${py}/bin/python3 - "$CONFIG" <<'PY'
import sys, json
import yaml

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f)

if data is None:
    data = {}

md = data.get("managed_directories")
if md is None:
    md = []
data["managed_directories"] = md

print(json.dumps(data))
PY
    )"

    [[ -n "$cfg_json" ]] || die "Parsed config JSON is empty (unexpected)"

    count="$(${py}/bin/python3 -c 'import json,sys; d=json.loads(sys.argv[1]); print(len(d.get("managed_directories") or []))' "$cfg_json")"
    [[ "$count" =~ ^[0-9]+$ ]] || die "Invalid managed_directories count: '$count'"

    log "===== Backup run started | entries=$count ====="
    if [[ "$count" -eq 0 ]]; then
      log "INFO   | No managed_directories; nothing to do."
      log "===== Backup run finished (OK) ====="
      exit 0
    fi

    # --------------------------------------------------------------------
    # IMPORTANT: rsync-over-ssh requires ssh stdin/stdout for protocol.
    # DO NOT use: ssh -n, -o StdinNull=yes, or stdin redirection for rsync.
    # --------------------------------------------------------------------

    # Safe for probes (does not carry rsync protocol)
    ssh_cmd_probe() {
      ${pkgs.openssh}/bin/ssh \
        -n \
        -i ${lib.escapeShellArg cfg.sshIdentityPath} \
        -o IdentitiesOnly=yes \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=accept-new \
        -o UserKnownHostsFile="$KNOWN_HOSTS" \
        -o ConnectTimeout=10 \
        -o ServerAliveInterval=10 \
        -o ServerAliveCountMax=3 \
        "$@"
    }

    remote_exists() {
      local remote="$1"
      local hostpart pathpart

      [[ "$remote" == *:* ]] || return 2
      hostpart="''${remote%%:*}"
      pathpart="''${remote#*:}"
      [[ -n "$pathpart" ]] || return 2

      ssh_cmd_probe "$hostpart" "test -d '$pathpart'"
    }

    do_rsync_backup() {
      local local_dir="$1"
      local remote="$2"

      local src_norm="''${local_dir%/}/"
      local dest_norm="''${remote%/}/"

      ${pkgs.rsync}/bin/rsync \
        ${lib.concatStringsSep " " (map lib.escapeShellArg cfg.rsyncFlags)} \
        -e "${pkgs.openssh}/bin/ssh -i ${lib.escapeShellArg cfg.sshIdentityPath} -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$KNOWN_HOSTS -o ConnectTimeout=10 -o ServerAliveInterval=10 -o ServerAliveCountMax=3" \
        --progress \
        "$src_norm" "$dest_norm"
    }

    # ---- Build a robust loop list (no TSV loop; no stdin consumption issues) ----
    mapfile -t entries_b64 < <(${py}/bin/python3 - "$cfg_json" <<'PY'
import sys, json, base64
data = json.loads(sys.argv[1])
items = data.get("managed_directories") or []

for i, d in enumerate(items):
    out = {
        "name": d.get("name", f"dir_{i}"),
        "local": d.get("local", ""),
        "remote": d.get("remote", ""),
        "marker": d.get("marker", ".restored_from_backup"),
        "backup": bool(d.get("backup", True)),
        "backup_when": d.get("backup_when", "marker_present"),
    }
    print(base64.b64encode(json.dumps(out).encode("utf-8")).decode("ascii"))
PY
    )

    pairs=0
    failures=0

    for b64 in "''${entries_b64[@]}"; do
      entry_json="$(printf '%s' "$b64" | ${pkgs.coreutils}/bin/base64 -d)"

      fields="$(${py}/bin/python3 - "$entry_json" <<'PY'
import sys, json
d = json.loads(sys.argv[1])
def s(x): return "" if x is None else str(x)
vals = [
  s(d.get("name","")),
  s(d.get("local","")),
  s(d.get("remote","")),
  s(d.get("marker",".restored_from_backup")),
  "true" if bool(d.get("backup", True)) else "false",
  s(d.get("backup_when","marker_present")),
]
print("\t".join(vals), end="")
PY
      )"

      IFS=$'\t' read -r name local remote marker backup backup_when <<< "$fields"
      [[ -z "$name" ]] && name="UNKNOWN"

      if [[ "$backup" != "true" ]]; then
        log "SKIP   | name=$name | backup=false"
        continue
      fi

      # Validate local/remote
      if [[ -z "$local" || "$local" != /* || "$local" == "/" ]]; then
        log "FATAL  | name=$name | invalid local path: '$local'"
        failures=$((failures+1))
        continue
      fi
      if [[ ! -d "$local" ]]; then
        log "FATAL  | name=$name | local dir missing: $local"
        failures=$((failures+1))
        continue
      fi
      if [[ -z "$remote" ]]; then
        log "FATAL  | name=$name | backup enabled but remote empty"
        failures=$((failures+1))
        continue
      fi

      # Marker gating (fail-closed, especially important with --delete)
      marker_path="$local/$marker"
      if [[ "$backup_when" == "marker_present" ]]; then
        if [[ ! -e "$marker_path" ]]; then
          log "FATAL  | name=$name | marker missing; refusing to back up with potential delete: $marker_path"
          failures=$((failures+1))
          continue
        fi
      else
        log "FATAL  | name=$name | unsupported backup_when='$backup_when'"
        failures=$((failures+1))
        continue
      fi

      # Ensure remote exists/reachable (fail-closed)
      log "CHECK  | name=$name | remote exists? $remote"
      if ! remote_exists "$remote"; then
        rc=$?
        if [[ "$rc" -eq 2 ]]; then
          log "FATAL  | name=$name | invalid remote (expected user@host:/path): '$remote'"
        else
          log "FATAL  | name=$name | remote missing/unreachable: '$remote'"
        fi
        failures=$((failures+1))
        continue
      fi

      pairs=$((pairs+1))

      log "START  | name=$name | rsync '$local/' -> '$remote/'"
      if do_rsync_backup "$local" "$remote"; then
        log "OK     | name=$name | $local/ -> $remote/"
      else
        log "FATAL  | name=$name | rsync failed"
        failures=$((failures+1))
        continue
      fi
    done

    if [[ $pairs -eq 0 ]]; then
      log "INFO   | No backup pairs configured."
      log "===== Backup run finished (OK) ====="
      exit 0
    fi

    if [[ $failures -eq 0 ]]; then
      log "===== Backup run finished (OK) ====="
      exit 0
    else
      log "===== Backup run finished (FAIL) | failures=$failures ====="
      exit 1
    fi
  '';
in
{
  options.services.homelab.backupRunner = {
    enable = lib.mkEnableOption "Homelab backup runner";

    schedule = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "systemd OnCalendar schedule (required when enabled).";
    };

    persistent = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run missed backups at next boot.";
    };

    timeoutSec = lib.mkOption {
      type = lib.types.int;
      default = 21600;
      description = "Maximum runtime before systemd kills the backup runner.";
    };

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/allans-home-lab/managed-directories/config.yaml";
      description = "Canonical managed directories config written by Ansible.";
    };

    # Uses the argv list passed from your flake config (no re-splitting)
    rsyncFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "-aHAX" "--numeric-ids" "--delete" ];
      description = "Rsync flags as argv tokens.";
    };

    sshIdentityPath = lib.mkOption {
      type = lib.types.str;
      default = "/root/.ssh/id_ed25519";
      description = "SSH identity used for remote backup.";
    };

    readablePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Allowlisted local source directories the backup runner may read under hardening.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.schedule != null;
        message = "services.homelab.backupRunner.schedule must be set when enable = true";
      }
      {
        assertion = cfg.readablePaths != [];
        message = "services.homelab.backupRunner.readablePaths must be set (fail-closed hardening: task needs explicit read allowlist).";
      }
    ];

    services.homelab.tasks.enable = lib.mkDefault true;

    services.homelab.tasks.tasks."backup-runner" = {
      description = "Homelab backup runner (managed-directories driven)";
      command = [ "${runnerScript}" ];

      schedule = cfg.schedule;
      persistent = cfg.persistent;
      timeoutSec = cfg.timeoutSec;

      requiresNetworkOnline = true;

      # Hardening
      protectHome = "read-only";
      readOnlyPaths = [ "/root/.ssh" cfg.configPath ] ++ cfg.readablePaths;

      # Writable HOME for ssh known_hosts + script temp/logs under StateDirectory
      stateDirectory = "homelab-backup-runner";
      environment = { HOME = "/var/lib/homelab-backup-runner"; };

      path = [
        pkgs.rsync
        pkgs.coreutils
        pkgs.openssh
        py
      ];

      taskLabel = "backup_runner";
    };
  };
}