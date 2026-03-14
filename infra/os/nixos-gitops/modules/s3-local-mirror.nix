{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.s3LocalMirror;

  # Convert Nix list -> bash array literal (properly quoted)
  bucketsBashArray =
    lib.concatMapStringsSep " " (b: lib.escapeShellArg b) cfg.buckets;

  runnerScript = pkgs.writeShellScript "homelab-s3-local-mirror" ''
    set -euo pipefail

    DEST_DIR=${lib.escapeShellArg cfg.destDir}
    SYNC_FLAGS=${lib.escapeShellArg cfg.syncFlags}

    ts(){ date '+%F %T%z'; }
    log(){ echo "$(ts) | $*"; }

    # Buckets injected by Nix (no runtime config file)
    BUCKETS=( ${bucketsBashArray} )

    if (( ''${#BUCKETS[@]} == 0 )); then
      log "No buckets configured; nothing to do."
      exit 0
    fi

    mkdir -p "$DEST_DIR"

    log "Starting S3 mirror run (dest=$DEST_DIR)"
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

    destDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/allans-home-lab/s3-mirror";
      description = "Destination base directory for local S3 mirrors.";
    };

    buckets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of S3 bucket names to mirror (e.g. [ \"bucket-a\" \"bucket-b\" ]).";
      example = [ "gitops-homelab-orchestrator-disks" "gitops-homelab-orchestrator-haos" ];
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
      {
        assertion = (cfg.buckets or [ ]) != [ ];
        message = "services.homelab.s3LocalMirror.buckets must be non-empty when enable = true";
      }
    ];

    # Ensure task framework is enabled
    services.homelab.tasks.enable = lib.mkDefault true;

    # Ensure dest dir exists
    systemd.tmpfiles.rules = [
      "d ${cfg.destDir} 0755 root root -"
    ];

    # Register task with framework
    services.homelab.tasks.tasks.s3-local-mirror = {
      description = "Homelab S3 local mirror";
      command = [ "${runnerScript}" ];

      schedule = cfg.schedule;
      persistent = cfg.persistent;
      timeoutSec = cfg.timeoutSec;

      requiresNetworkOnline = true;

      # needs to write mirror output
      readWritePaths = [ cfg.destDir ];

      # keep awscli available
      path = [
        pkgs.awscli2
        pkgs.coreutils
      ];

      taskLabel = "s3_local_mirror";

      # ---- AWS creds fix (works with hardening enabled) ----
      # /root is hidden when ProtectHome=yes; make it visible (read-only is enough)
      protectHome = "read-only";

      # Create a writable state dir and use it as HOME so awscli can cache safely
      stateDirectory = "homelab-s3-local-mirror";
      environment = {
        HOME = "/var/lib/homelab-s3-local-mirror";
        AWS_SHARED_CREDENTIALS_FILE = "/root/.aws/credentials";
        AWS_CONFIG_FILE            = "/root/.aws/config";
        AWS_CLI_CACHE_DIR          = "/var/lib/homelab-s3-local-mirror/aws-cli-cache";
      };

      # Optional belt-and-suspenders: explicitly allow reading the creds dir
      readOnlyPaths = [ "/root/.aws" ];
    };
  };
}