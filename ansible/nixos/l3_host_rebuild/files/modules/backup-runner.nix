{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.backupRunner;

  py = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);

  runnerScript = pkgs.writeShellScript "homelab-backup-runner" ''
    set -Eeuo pipefail

    CONFIG=${lib.escapeShellArg cfg.configPath}

    HOME_DIR="''${HOME:-/tmp}"
    KNOWN_HOSTS="$HOME_DIR/known_hosts"

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

    # Emit TSV: name local remote marker backup restore
    ${py}/bin/python3 - "$cfg_json" <<'PY' > "$HOME_DIR/entries.tsv"
import sys, json
data = json.loads(sys.argv[1])
items = data.get("managed_directories") or []

def b(x): return "true" if bool(x) else "false"

for i, d in enumerate(items):
    name   = d.get("name", f"dir_{i}")
    local  = d.get("local", "")
    remote = d.get("remote", "")
    marker = d.get("marker", ".restored_from_backup")
    backup = bool(d.get("backup", True))
    restore = bool(d.get("restore", True))
    backup_when = d.get("backup_when", "marker_present")
    print("\t".join([name, local, remote, marker, b(backup), b(restore), backup_when]))
PY

    pairs=0
    failures=0

    ssh_cmd() {
      ${pkgs.openssh}/bin/ssh \
        -i ${lib.escapeShellArg cfg.sshIdentityPath} \
        -o IdentitiesOnly=yes \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=accept-new \
        -o UserKnownHostsFile="$KNOWN_HOSTS" \
        -o ConnectTimeout=5 \
        "$@"
    }

    remote_parent_exists() {
      local remote="$1"
      local hostpart pathpart
      [[ "$remote" == *:* ]] || return 2
      hostpart="''${remote%%:*}"
      pathpart="''${remote#*:}"
      [[ -n "$pathpart" ]] || return 2
      ssh_cmd "$hostpart" "test -d '$pathpart'"
    }

    log "===== Backup run started ====="

    while IFS=$'\t' read -r name local remote marker backup restore backup_when; do
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
      if ! remote_parent_exists "$remote"; then
        rc=$?
        if [[ "$rc" -eq 2 ]]; then
          log "FATAL  | name=$name | invalid remote (expected user@host:/path): '$remote'"
        else
          log "FATAL  | name=$name | remote missing/unreachable: '$remote'"
        fi
        failures=$((failures+1))
        continue
      fi

      src_norm="''${local%/}/"
      dest_norm="''${remote%/}/"

      pairs=$((pairs+1))

      log "START  | name=$name | rsync '$src_norm' -> '$dest_norm'"

      ${pkgs.rsync}/bin/rsync \
        ${lib.concatStringsSep " " (map lib.escapeShellArg cfg.rsyncFlags)} \
        -e "${pkgs.openssh}/bin/ssh -i ${lib.escapeShellArg cfg.sshIdentityPath} -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$KNOWN_HOSTS -o ConnectTimeout=5" \
        --progress \
        "$src_norm" "$dest_norm" \
        || { log "FATAL  | name=$name | rsync failed"; failures=$((failures+1)); continue; }

      log "OK     | name=$name | $src_norm -> $dest_norm"

    done < "$HOME_DIR/entries.tsv"

    if [[ $pairs -eq 0 ]]; then
      log "INFO   | No backup pairs configured."
      log "===== Backup run finished (OK) ====="
      exit 0
    fi

    if [[ $failures -eq 0 ]]; then
      log "===== Backup run finished (OK) ====="
      exit 0
    else
      log "===== Backup run finished (FAIL) ====="
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

    # NEW: where to read managed directories config
    configPath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/allans-home-lab/managed-directories/config.yaml";
      description = "Canonical managed directories config written by Ansible.";
    };

    # NEW: rsync flags as argv list
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

    # NEW: allowlist of local sources under hardening
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

      # Writable HOME for ssh known_hosts + script temp files under StateDirectory
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