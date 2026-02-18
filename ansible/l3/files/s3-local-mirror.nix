{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.s3LocalMirror;

  runnerScript = pkgs.writeShellScript "homelab-s3-local-mirror" ''
    set -euo pipefail

    CONFIG_FILE=${lib.escapeShellArg cfg.configFile}
    DEST_DIR=${lib.escapeShellArg cfg.destDir}
    SYNC_FLAGS=${lib.escapeShellArg cfg.syncFlags}

    ts(){ date '+%F %T%z'; }
    log(){ echo "$(ts) | $*"; }

    trim() {
      local s="$1"
      s="''${s#"''${s%%[![:space:]]*}"}"
      s="''${s%"''${s##*[![:space:]]}"}"
      printf '%s' "$s"
    }

    if [[ ! -f "$CONFIG_FILE" ]]; then
      log "No bucket config file found at $CONFIG_FILE; nothing to do."
      exit 0
    fi

    BUCKETS=()

    while IFS= read -r raw || [[ -n "$raw" ]]; do
      # strip comments, trim, skip empties
      raw="''${raw%%#*}"
      raw="$(trim "$raw")"
      [[ -z "$raw" ]] && continue

      # allow comma-separated buckets on one line
      IFS=',' read -r -a parts <<< "$raw"
      for p in "''${parts[@]}"; do
        p="$(trim "$p")"
        [[ -z "$p" ]] && continue
        BUCKETS+=("$p")
      done
    done < "$CONFIG_FILE"

    if (( ''${#BUCKETS[@]} == 0 )); then
      log "Bucket config file is empty ($CONFIG_FILE); nothing to do."
      exit 0
    fi

    mkdir -p "$DEST_DIR"

    log "Starting S3 mirror run (config=$CONFIG_FILE)"
    failures=0

    for bucket in "''${BUCKETS[@]}"; do
      dest="$DEST_DIR/$bucket"
      mkdir -p "$dest"
      log "SYNC  s3://$bucket -> $dest"

      # shellcheck disable=SC2086
      if aws s3 sync "s3://$bucket" "$dest" $SYNC_FLAGS; then
        log "OK    $bucket"
      else
        log "ERROR $bucket"
        ((failures++))
      fi
    done

    if (( failures > 0 )); then
      log "Finished with $failures error(s)"
      exit 1
    else
      log "Finished OK"
      exit 0
    fi
  '';
in
{
  options.services.homelab.s3LocalMirror = {
    enable = lib.mkEnableOption "Homelab S3 local mirror (aws s3 sync to local dir)";

    baseDir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/allans-home-lab/s3";
      description = "Base directory for S3 mirror configuration files.";
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/allans-home-lab/s3/buckets.conf";
      description = "Bucket list config file (one bucket per line; blank lines and # comments allowed).";
    };

    destDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/allans-home-lab/s3-mirror";
      description = "Destination base directory for local S3 mirrors.";
    };

    schedule = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "systemd OnCalendar schedule (required when enabled).";
    };

    persistent = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run missed syncs at next boot.";
    };

    timeoutSec = lib.mkOption {
      type = lib.types.int;
      default = 21600; # 6 hours
      description = "Maximum runtime before systemd kills the mirror run.";
    };

    syncFlags = lib.mkOption {
      type = lib.types.str;
      description = "Raw aws s3 sync flags string (DO NOT CHANGE semantics). Example: \"--delete --only-show-errors\"";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.schedule != null;
        message = "services.homelab.s3LocalMirror.schedule must be set when enable = true";
      }
      {
        assertion = (cfg.syncFlags or "") != "";
        message = "services.homelab.s3LocalMirror.syncFlags must be set when enable = true";
      }
    ];

    # Ensure task framework is enabled
    services.homelab.tasks.enable = lib.mkDefault true;

    # Ensure directories exist
    systemd.tmpfiles.rules = [
      "d ${cfg.baseDir} 0755 root root -"
      "d ${builtins.dirOf cfg.configFile} 0755 root root -"
      "d ${cfg.destDir} 0755 root root -"
    ];

    # Declarative default config file (comments, no entries)
    environment.etc."allans-home-lab/s3/buckets.conf" = {
      text = ''
# Managed by NixOS (L3 scaffolding) + Ansible (L4 entries).
# One bucket per line. Blank lines and # comments are allowed.
#
# Examples:
#   gitops-homelab-orchestrator-disks
#   gitops-homelab-orchestrator-haos
#
# Comma-separated buckets on one line are also accepted:
#   bucket-a, bucket-b
'';
      mode = "0644";
    };

    # Register task with framework
    services.homelab.tasks.tasks.s3-local-mirror = {
      description = "Homelab S3 local mirror";
      command = [ "${runnerScript}" ];

      schedule = cfg.schedule;
      persistent = cfg.persistent;
      timeoutSec = cfg.timeoutSec;

      requiresNetworkOnline = true;
      readWritePaths = [ cfg.destDir ];

      # Ensure aws is available even if you later stop installing it globally
      path = [
        pkgs.awscli2
        pkgs.coreutils
      ];

      taskLabel = "s3_local_mirror";
    };
  };
}
