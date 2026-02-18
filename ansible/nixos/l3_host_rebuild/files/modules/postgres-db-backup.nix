{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.postgresDbBackup;

  keepDays = 14;

  runnerScript = pkgs.writeShellScript "homelab-postgres-db-backup" ''
    set -euo pipefail

    ts() { date '+%F %T%z'; }
    log(){ echo "$(ts) | $*"; }

    ENV_FILE=${lib.escapeShellArg cfg.envFile}
    BACKUP_DIR=${lib.escapeShellArg cfg.backupDir}
    KEEP_DAYS=${toString keepDays}

    if [[ ! -f "$ENV_FILE" ]]; then
      log "No env file found ($ENV_FILE); nothing to do."
      exit 0
    fi

    # shellcheck disable=SC1090
    source "$ENV_FILE"

    # Validate required vars when env file exists
    : "''${DB:?missing DB in env file}"
    : "''${USER:?missing USER in env file}"
    : "''${PASS:?missing PASS in env file}"
    : "''${CONTAINER:?missing CONTAINER in env file}"

    EXTRA_ARGS="''${EXTRA_ARGS:-}"

    timestamp="$(date +"%Y%m%d-%H%M%S")"
    outfile="$BACKUP_DIR/''${DB}-''${timestamp}.dump"

    mkdir -p "$BACKUP_DIR"

    log "Starting Postgres dump…"
    log "Mode: docker exec → ''${CONTAINER} (db=''${DB} user=''${USER})"

    # Note: pg_dump runs inside the container; we don't need local postgres packages.
    export PGPASSWORD="''${PASS}"

    # shellcheck disable=SC2086
    docker exec -e PGPASSWORD="''${PASS}" "''${CONTAINER}" \
      pg_dump -U "''${USER}" -d "''${DB}" -Fc ''${EXTRA_ARGS} > "''${outfile}"

    log "Dump complete: ''${outfile}"

    # Prune old dumps for this DB
    find "$BACKUP_DIR" -type f -name "''${DB}-*.dump" -mtime +$KEEP_DAYS -print -delete || true
    log "Prune complete (keep $KEEP_DAYS days)"
  '';
in
{
  options.services.homelab.postgresDbBackup = {
    enable = lib.mkEnableOption "Homelab Postgres DB backup (pg_dump via docker exec)";

    envFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/allans-home-lab/db/dump-postgres-db.env";
      description = "Env file path written by L4 (DB/USER/PASS/EXTRA_ARGS/CONTAINER).";
    };

    backupDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/allans-home-lab/postgres-backup";
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
    ];

    services.homelab.tasks.enable = lib.mkDefault true;

    # Ensure directories exist
    systemd.tmpfiles.rules = [
      "d ${builtins.dirOf cfg.envFile} 0755 root root -"
      "d ${cfg.backupDir} 0755 root root -"
    ];

    # Declarative env-file scaffold (comments only; L4 overwrites contents)
    environment.etc."allans-home-lab/db/dump-postgres-db.env" = {
      text = ''
# Managed by NixOS (L3 scaffolding) + Ansible (L4 values).
# If this file is absent, the scheduled job is a no-op (exit 0).
# If present, required keys must be set or the job fails fast.
#
# Required:
#   DB=your_db_name
#   USER=your_db_user
#   PASS=your_db_password
#   CONTAINER=your_postgres_container_name_or_id
#
# Optional:
#   EXTRA_ARGS=additional pg_dump args (e.g. "--no-owner --no-privileges")
#
# Example:
# DB="appdb"
# USER="postgres"
# PASS="supersecret"
# EXTRA_ARGS=""
# CONTAINER="my-postgres"
'';
      mode = "0644";
    };

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
