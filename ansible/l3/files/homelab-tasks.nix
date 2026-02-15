{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.tasks;

  # Allow: letters, digits, underscore, dash, dot
  taskSlugRegex = "^[A-Za-z0-9_.-]+$";

  # Convert an argv list into a shell-escaped command line.
  escapeArgv = argv: lib.concatStringsSep " " (map lib.escapeShellArg argv);

  # Per-task wrapper script:
  # - runs the command
  # - measures duration
  # - emits atomic textfile-collector metrics
  mkTaskWrapperScript = { taskLabel, commandLine }:
    pkgs.writeShellScript "homelab-task-wrap-${taskLabel}" ''
      set -euo pipefail

      TEXTDIR=${lib.escapeShellArg cfg.textfileDir}
      OUT="$TEXTDIR/homelab_task_${taskLabel}.prom"

      if [[ ! -d "$TEXTDIR" ]]; then
        echo "ERROR: textfile directory does not exist: $TEXTDIR" >&2
        exit 1
      fi

      # Temp file in same dir so mv is atomic (same filesystem).
      TMP="$(mktemp "$OUT.tmp.XXXXXX")"
      cleanup() { rm -f "$TMP" 2>/dev/null || true; }
      trap cleanup EXIT

      start_ns="$(date +%s%N)"
      rc=0

      ${commandLine} || rc=$?

      end_ns="$(date +%s%N)"
      end_epoch="$(date +%s)"

      # Duration in seconds (float)
      duration="$(awk -v s="$start_ns" -v e="$end_ns" 'BEGIN { printf "%.6f", (e-s)/1000000000 }')"

      {
        echo "# HELP homelab_task_last_success_unix Unix timestamp of last successful run"
        echo "# TYPE homelab_task_last_success_unix gauge"
        if [[ "$rc" -eq 0 ]]; then
          echo "homelab_task_last_success_unix{task=\"${taskLabel}\"} $end_epoch"
        fi

        echo "# HELP homelab_task_last_run_unix Unix timestamp of last run (success or failure)"
        echo "# TYPE homelab_task_last_run_unix gauge"
        echo "homelab_task_last_run_unix{task=\"${taskLabel}\"} $end_epoch"

        echo "# HELP homelab_task_last_exit_code Last exit code (0=success)"
        echo "# TYPE homelab_task_last_exit_code gauge"
        echo "homelab_task_last_exit_code{task=\"${taskLabel}\"} $rc"

        echo "# HELP homelab_task_last_duration_seconds Duration of last run in seconds"
        echo "# TYPE homelab_task_last_duration_seconds gauge"
        echo "homelab_task_last_duration_seconds{task=\"${taskLabel}\"} $duration"
      } >"$TMP"

      chmod 0644 "$TMP"
      mv -f "$TMP" "$OUT"

      trap - EXIT
      exit "$rc"
    '';

  mkOneTaskUnits = name: t:
    let
      unitName = "homelab-task-${name}";
      taskLabel = if t.taskLabel == null then name else t.taskLabel;

      commandLine = escapeArgv t.command;
      wrapper = mkTaskWrapperScript { inherit taskLabel commandLine; };

      baseAfter =
        [ "network.target" ]
        ++ lib.optionals t.requiresNetworkOnline [ "network-online.target" ];

      baseWants =
        lib.optionals t.requiresNetworkOnline [ "network-online.target" ];

      rwPaths = [ cfg.textfileDir ] ++ t.readWritePaths;

      # Provide a reliable PATH to the unit via NixOS-native systemd.services.<name>.path
      pathPkgs = [ pkgs.coreutils pkgs.gawk ] ++ t.path;
    in
    {
      services."${unitName}" = {
        description = if t.description == null then "Homelab task: ${name}" else t.description;
        after = baseAfter;
        wants = baseWants;

        # NixOS idiom: this generates PATH=... for the unit.
        path = pathPkgs;

        unitConfig = lib.mkIf (t.requiresMountsFor != []) {
          RequiresMountsFor = t.requiresMountsFor;
        };

        serviceConfig =
          {
            Type = "oneshot";
            TimeoutSec = t.timeoutSec;

            # journald is default; make it explicit
            StandardOutput = "journal";
            StandardError = "journal";

            ExecStart = "${wrapper}";
          }
          // (lib.optionalAttrs (t.workingDirectory != null) {
            WorkingDirectory = t.workingDirectory;
          })
          // (lib.optionalAttrs cfg.hardening.enable {
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            RestrictRealtime = true;

            # Allow writing only where we explicitly need it
            ReadWritePaths = rwPaths;
          });
      };

      timers."${unitName}" = lib.mkIf (t.schedule != null) {
        description = "Timer for ${unitName}";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = t.schedule;
          Persistent = t.persistent;
          Unit = "${unitName}.service";
        };
      };
    };

  enabledTasks =
    lib.filterAttrs (_: t: t.enable) cfg.tasks;

  allUnits =
    lib.foldl' lib.recursiveUpdate { services = { }; timers = { }; }
      (lib.mapAttrsToList mkOneTaskUnits enabledTasks);

in
{
  options.services.homelab.tasks = {
    enable = lib.mkEnableOption "Homelab task framework (systemd + journald + node_exporter textfile metrics)";

    textfileDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/node_exporter/textfile_collector";
      description = "Node Exporter textfile collector directory for homelab_task_*.prom metrics.";
    };

    hardening.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable conservative systemd hardening defaults for all homelab tasks.";
    };

    tasks = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };

          description = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };

          # argv list (no shell)
          command = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Command argv list to run for this task.";
          };

          # systemd OnCalendar string, or null for no timer (manual runs only)
          schedule = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "systemd OnCalendar value. If null, no timer is created.";
          };

          persistent = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "If true, missed runs execute after downtime (systemd timer Persistent=).";
          };

          timeoutSec = lib.mkOption {
            type = lib.types.int;
            default = 3600;
            description = "systemd service TimeoutSec.";
          };

          workingDirectory = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };

          requiresNetworkOnline = lib.mkOption {
            type = lib.types.bool;
            default = true; # per your choice 1A
            description = "If true, the task orders after and wants network-online.target.";
          };

          requiresMountsFor = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Paths that must be mounted before running (systemd RequiresMountsFor=).";
          };

          path = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [];
            description = "Packages whose bin dirs are added to PATH for this task.";
          };

          readWritePaths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Extra writable paths when hardening is enabled (systemd ReadWritePaths=).";
          };

          taskLabel = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Label used for metrics filename + {task=\"...\"}. Defaults to the task key.";
          };
        };
      }));
      default = {};
      description = "Homelab tasks keyed by name.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      let
        labels = lib.mapAttrsToList (n: t: if t.taskLabel == null then n else t.taskLabel) enabledTasks;
        bad = lib.filter (l: (builtins.match taskSlugRegex l) == null) labels;
      in [
        {
          assertion = bad == [];
          message =
            "services.homelab.tasks: invalid taskLabel(s): ${lib.concatStringsSep ", " bad}. Must match ${taskSlugRegex}";
        }
      ];

    # Ensure the textfile collector directory exists
    systemd.tmpfiles.rules = [
      "d ${cfg.textfileDir} 0755 root root -"
    ];

    systemd.services = allUnits.services;
    systemd.timers = allUnits.timers;
  };
}
