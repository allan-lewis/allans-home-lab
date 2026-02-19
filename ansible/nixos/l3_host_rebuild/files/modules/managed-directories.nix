{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.managedDirectories;

  # Python with PyYAML available (so `import yaml` works).
  py = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);

  rehydrateScript = pkgs.writeShellScript "homelab-managed-dirs-rehydrate" ''
    set -Eeuo pipefail

    CONFIG=${lib.escapeShellArg cfg.configPath}

    HOME_DIR="''${HOME:-/tmp}"
    LOGFILE="$HOME_DIR/rehydrate.log"
    KNOWN_HOSTS="$HOME_DIR/known_hosts"

    mkdir -p "$HOME_DIR"
    touch "$LOGFILE"
    chmod 0644 "$LOGFILE"
    exec > >(tee -a "$LOGFILE") 2>&1

    timestamp() { date +"%Y-%m-%d %H:%M:%S%z"; }
    log() { echo "$(timestamp) | $*"; }
    die() { log "FATAL  | $*"; exit 1; }

    on_err() {
      rc=$?
      log "FATAL  | rehydrate failed (exit=$rc)"
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

    # ---- Count entries using argv (no stdin surprises) ----
    count="$(${py}/bin/python3 -c 'import json,sys; d=json.loads(sys.argv[1]); print(len(d.get("managed_directories") or []))' "$cfg_json")"
    [[ "$count" =~ ^[0-9]+$ ]] || die "Invalid managed_directories count: '$count'"

    log "===== Managed dirs rehydrate started | entries=$count ====="

    if [[ "$count" -eq 0 ]]; then
      log "INFO   | No managed_directories; nothing to do."
      log "===== Managed dirs rehydrate finished (OK) ====="
      exit 0
    fi

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

    remote_exists() {
      local remote="$1"
      local hostpart pathpart

      [[ "$remote" == *:* ]] || return 2
      hostpart="''${remote%%:*}"
      pathpart="''${remote#*:}"
      [[ -n "$pathpart" ]] || return 2

      ssh_cmd "$hostpart" "test -d '$pathpart'"
    }

    do_rsync_restore() {
      local remote="$1"
      local local_dir="$2"

      local remote_norm="''${remote%/}/"
      local local_norm="''${local_dir%/}/"

      ${pkgs.rsync}/bin/rsync \
        ${lib.concatStringsSep " " (map lib.escapeShellArg cfg.rsyncFlags)} \
        -e "${pkgs.openssh}/bin/ssh -i ${lib.escapeShellArg cfg.sshIdentityPath} -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$KNOWN_HOSTS -o ConnectTimeout=5" \
        --progress \
        "$remote_norm" "$local_norm"
    }

    # ---- Emit TSV safely using argv JSON ----
    ${py}/bin/python3 - "$cfg_json" <<'PY' > "$HOME_DIR/entries.tsv"
import sys, json

data = json.loads(sys.argv[1])
items = data.get("managed_directories") or []

def b(x): return "true" if bool(x) else "false"

for i, d in enumerate(items):
    name   = d.get("name", f"dir_{i}")
    local  = d.get("local", "")
    remote = d.get("remote", "")
    owner  = d.get("owner", "root")
    group  = d.get("group", owner)
    marker = d.get("marker", ".restored_from_backup")
    restore = bool(d.get("restore", True))
    restore_when = d.get("restore_when", "empty_and_marker_missing")

    # Tab-separated, one entry per line
    print("\t".join([name, local, remote, owner, group, marker, b(restore), restore_when]))
PY

    failures=0
    restored=0

    while IFS=$'\t' read -r name local remote owner group marker restore restore_when; do
      [[ -z "$name" ]] && name="UNKNOWN"

      if [[ "$restore" != "true" ]]; then
        log "SKIP   | name=$name | restore=false"
        continue
      fi

      if [[ "$restore_when" != "empty_and_marker_missing" ]]; then
        log "FATAL  | name=$name | unsupported restore_when='$restore_when'"
        failures=$((failures+1))
        continue
      fi

      if [[ -z "$local" || "$local" != /* || "$local" == "/" ]]; then
        log "FATAL  | name=$name | invalid local path: '$local'"
        failures=$((failures+1))
        continue
      fi

      marker_path="$local/$marker"

      # Must exist (Nix tmpfiles responsibility)
      if [[ ! -d "$local" ]]; then
        log "FATAL  | name=$name | local dir missing (expected Nix tmpfiles): $local"
        failures=$((failures+1))
        continue
      fi

      # Already hydrated
      if [[ -e "$marker_path" ]]; then
        log "OK     | name=$name | marker present; hydrated"
        continue
      fi

      # Fail-closed ambiguity: non-empty but marker missing
      if [[ -n "$(ls -A "$local" 2>/dev/null || true)" ]]; then
        log "FATAL  | name=$name | non-empty but marker missing; refusing: $local"
        failures=$((failures+1))
        continue
      fi

      # Needs restore: empty + marker missing
      if [[ -z "$remote" ]]; then
        log "FATAL  | name=$name | restore enabled but remote empty"
        failures=$((failures+1))
        continue
      fi

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

      log "START  | name=$name | restore '$remote' -> '$local'"
      if do_rsync_restore "$remote" "$local"; then
        log "CHOWN  | name=$name | chown -R $owner:$group '$local'"
        ${pkgs.coreutils}/bin/chown -R "$owner:$group" "$local"

        log "MARK   | name=$name | write marker: $marker_path"
        tmp="$(mktemp "$local/.marker.XXXXXX")"
        printf '%s\n' "$(timestamp) restored from $remote" > "$tmp"
        ${pkgs.coreutils}/bin/chown "$owner:$group" "$tmp"
        ${pkgs.coreutils}/bin/chmod 0644 "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$marker_path"

        # Post-check
        if [[ -e "$marker_path" && -n "$(ls -A "$local" 2>/dev/null || true)" ]]; then
          log "OK     | name=$name | restored + marked"
          restored=$((restored+1))
        else
          log "FATAL  | name=$name | post-check failed (marker/contents)"
          failures=$((failures+1))
        fi
      else
        log "FATAL  | name=$name | rsync failed"
        failures=$((failures+1))
      fi

    done < "$HOME_DIR/entries.tsv"

    if [[ "$failures" -eq 0 ]]; then
      log "===== Managed dirs rehydrate finished (OK) | restored=$restored ====="
      exit 0
    else
      log "===== Managed dirs rehydrate finished (FAIL) | failures=$failures restored=$restored ====="
      exit 1
    fi
  '';
in
{
  options.services.homelab.managedDirectories = {
    enable = lib.mkEnableOption "Managed directories (rehydrate oneshot task)";

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/allans-home-lab/managed-directories/config.yaml";
      description = "Canonical config written by Ansible.";
    };

    sshIdentityPath = lib.mkOption {
      type = lib.types.str;
      default = "/root/.ssh/id_ed25519";
      description = "SSH identity used for remote restore.";
    };

    rsyncFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "-aHAX" "--numeric-ids" ];
    };

    writablePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Allowlisted managed local directories the rehydrate task may write into (ReadWritePaths).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.writablePaths != [];
        message = "services.homelab.managedDirectories.writablePaths must be set (task hardening requires explicit write allowlist).";
      }
    ];

    services.homelab.tasks.enable = lib.mkDefault true;

    systemd.tmpfiles.rules = [
      "d /etc/allans-home-lab/managed-directories 0755 root root -"
    ];

    services.homelab.tasks.tasks."managed-dirs-rehydrate" = {
      description = "Managed directories rehydrate (restore if empty + marker missing; fail-closed)";
      command = [ "${rehydrateScript}" ];

      schedule = null;
      persistent = false;
      timeoutSec = 3600;

      requiresNetworkOnline = true;

      stateDirectory = "homelab-managed-dirs";
      environment = { HOME = "/var/lib/homelab-managed-dirs"; };

      protectHome = "read-only";
      readOnlyPaths = [ "/root/.ssh" cfg.configPath ];

      readWritePaths = cfg.writablePaths;

      path = [
        pkgs.rsync
        pkgs.openssh
        pkgs.coreutils
        py
      ];

      taskLabel = "managed_dirs_rehydrate";
    };
  };
}
