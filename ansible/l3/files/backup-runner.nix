{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.backupRunner;
  confDir = "${cfg.baseDir}/backup.conf.d";

  runnerScript = pkgs.writeShellScript "homelab-backup-runner" ''
    set -uo pipefail

    CONF_DIR=${lib.escapeShellArg confDir}
    RSYNC_FLAGS=${lib.escapeShellArg cfg.rsyncFlags}

    timestamp() { date +"%Y-%m-%d %H:%M:%S%z"; }
    log() { echo "$(timestamp) | $*"; }

    if [[ ! -d "$CONF_DIR" ]]; then
      log "ERROR  | backup conf dir missing: $CONF_DIR"
      exit 1
    fi

    pairs=0
    failures=0

    log "===== Backup run started ====="

    # Iterate fragments safely (space-safe, stable order)
    while IFS= read -r -d $'\0' file; do
      log "FILE   | Processing config: $file"

      while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue

        if [[ "$line" =~ ^[[:space:]]*(.+)[[:space:]]+::[[:space:]]+(.+)[[:space:]]*$ ]]; then
          src="''${BASH_REMATCH[1]}"
          dest="''${BASH_REMATCH[2]}"

          src_norm="''${src%/}/"
          dest_norm="''${dest%/}/"

          ((pairs++))

          log "START  | rsync $RSYNC_FLAGS '$src_norm' -> '$dest_norm'"

          # shellcheck disable=SC2086
          rsync $RSYNC_FLAGS \
            -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes" \
            --progress \
            "$src_norm" "$dest_norm"

          rc=$?

          if [[ $rc -eq 0 ]]; then
            log "OK     | $src_norm -> $dest_norm"
          else
            log "ERROR  | $src_norm -> $dest_norm | exit=$rc"
            ((failures++))
          fi

        else
          log "WARN   | malformed pair (expected 'SRC :: DEST'): '$line'"
          ((failures++))
        fi

      done < "$file"

    done < <(find "$CONF_DIR" -type f -name '*.conf' -print0 | sort -z)

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

    baseDir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/allans-home-lab/backup";
      description = "Base directory for backup runner configuration.";
    };

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

    rsyncFlags = lib.mkOption {
      type = lib.types.str;
      description = "Raw rsync flags string (must match non-NixOS hosts).";
    };
  };

  config = lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = cfg.schedule != null;
        message = "services.homelab.backupRunner.schedule must be set when enable = true";
      }
    ];

    services.homelab.tasks.enable = lib.mkDefault true;

    # Ensure directories exist
    systemd.tmpfiles.rules = [
      "d ${cfg.baseDir} 0755 root root -"
      "d ${confDir} 0755 root root -"
    ];

    # Declarative default fragment
    environment.etc."allans-home-lab/backup/backup.conf.d/00-default.conf" = {
      text = ''
# This is a backup fragment for the homelab backup runner.
#
# Format:
#   SRC :: DEST
#
# - SRC:  local source path (directory to back up)
# - DEST: destination path (can be local or remote rsync target,
#         e.g. user@host:/path)
#
# Lines starting with '#' or blank lines are ignored.
#
# All fragment files in:
#   ${confDir}
# are processed in sorted order.
#
# Each valid line represents a backup pair.
# Failures in one pair do NOT prevent other pairs from running.
# The overall run exits non-zero if any pair fails.
#
# Example:
#   /var/lib/docker/volumes/myapp_db/_data :: nas:/tank/backups/myapp/db
#   /home :: user@server:/backups/home
#
# Add additional *.conf files in this directory via L4.
'';
      mode = "0644";
    };

    # Register task with framework
    services.homelab.tasks.tasks.backup-runner = {
      description = "Homelab backup runner";
      command = [ "${runnerScript}" ];

      schedule = cfg.schedule;
      persistent = cfg.persistent;
      timeoutSec = cfg.timeoutSec;

      requiresNetworkOnline = true;
      readWritePaths = [ cfg.baseDir ];

      path = [
        pkgs.rsync
        pkgs.coreutils
        pkgs.gawk
        pkgs.gnused
        pkgs.findutils
        pkgs.openssh
      ];

      taskLabel = "backup_runner";
    };
  };
}
