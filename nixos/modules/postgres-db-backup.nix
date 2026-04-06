{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.postgresDbBackup;

  keepDays = 14;

  runnerScript = pkgs.writeShellScript "homelab-postgres-db-backup" ''
    set -euo pipefail

    ts() { date '+%F %T%z'; }
    log(){ echo "$(ts) | $*"; }
    die(){ log "FATAL  | $*"; exit 1; }

    BACKUP_DIR=${lib.escapeShellArg cfg.backupDir}
    KEEP_DAYS=${toString keepDays}

    DB=${lib.escapeShellArg cfg.db}
    DB_USER=${lib.escapeShellArg cfg.user}
    CONTAINER=${lib.escapeShellArg cfg.container}
    EXTRA_ARGS=${lib.escapeShellArg cfg.extraArgs}

    PASS_FILE=${lib.escapeShellArg cfg.passwordFile}

    [[ -n "''${DB}" ]] || die "DB is empty"
    [[ -n "''${DB_USER}" ]] || die "USER is empty"
    [[ -n "''${CONTAINER}" ]] || die "CONTAINER is empty"
    [[ -n "''${PASS_FILE}" ]] || die "passwordFile is empty"

    if [[ ! -f "''${PASS_FILE}" ]]; then
      die "Password file not found: ''${PASS_FILE}"
    fi

    PASS="$(cat "''${PASS_FILE}")"
    if [[ -z "''${PASS}" ]]; then
      die "Password file is empty: ''${PASS_FILE}"
    fi

    mkdir -p "''${BACKUP_DIR}"

    timestamp="$(date +"%Y%m%d-%H%M%S")"
    outfile="''${BACKUP_DIR}/''${DB}-''${timestamp}.dump"

    log "Starting Postgres dump…"
    log "Mode: docker exec → ''${CONTAINER} (db=''${DB} user=''${DB_USER})"

    # shellcheck disable=SC2086
    docker exec -e PGPASSWORD="''${PASS}" "''${CONTAINER}" \
      pg_dump -U "''${DB_USER}" -d "''${DB}" -Fc ''${EXTRA_ARGS} > "''${outfile}"

    log "Dump complete: ''${outfile}"

    # Prune old dumps for this DB
    find "''${BACKUP_DIR}" -type f -name "''${DB}-*.dump" -mtime +''${KEEP_DAYS} -print -delete || true
    log "Prune complete (keep ''${KEEP_DAYS} days)"
  '';
in
{
  options.services.homelab.postgresDbBackup = {
    enable = lib.mkEnableOption "Homelab Postgres DB backup (pg_dump via docker exec)";

    db = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Database name to dump.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Database user for pg_dump.";
    };

    container = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Docker container name/ID running Postgres (target for docker exec).";
    };

    extraArgs = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Additional pg_dump args (e.g. \"--no-owner --no-privileges\").";
    };

    passwordFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/allans-home-lab/secrets/postgres_dump_pass";
      description = "Path to a file containing the Postgres password (read at runtime).";
    };

    backupDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/postgres-db-dumps";
      description = "Directory where dumps are written.";
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
      default = 7200; # 2 hours
      description = "Maximum runtime before systemd kills the backup run.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.schedule != null;
        message = "services.homelab.postgresDbBackup.schedule must be set when enable = true";
      }
      {
        assertion = cfg.db != "";
        message = "services.homelab.postgresDbBackup.db must be set when enable = true";
      }
      {
        assertion = cfg.user != "";
        message = "services.homelab.postgresDbBackup.user must be set when enable = true";
      }
      {
        assertion = cfg.container != "";
        message = "services.homelab.postgresDbBackup.container must be set when enable = true";
      }
      {
        assertion = cfg.passwordFile != "";
        message = "services.homelab.postgresDbBackup.passwordFile must be set when enable = true";
      }
    ];

    services.homelab.tasks.enable = lib.mkDefault true;

    # Ensure dirs exist (do NOT create secret file)
    systemd.tmpfiles.rules = [
      "d ${cfg.backupDir} 0755 root root -"
      "d ${builtins.dirOf cfg.passwordFile} 0755 root root -"
    ];

    services.homelab.tasks.tasks.postgres-db-backup = {
      description = "Homelab Postgres DB backup";
      command = [ "${runnerScript}" ];

      schedule = cfg.schedule;
      persistent = cfg.persistent;
      timeoutSec = cfg.timeoutSec;

      requiresNetworkOnline = false;
      readWritePaths = [ cfg.backupDir ];

      path = [
        pkgs.docker
        pkgs.coreutils
        pkgs.findutils
      ];

      taskLabel = "postgres_db_backup";
    };
  };
}