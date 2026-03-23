{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.hello;

  helloScript = pkgs.writeShellScript "homelab-hello-append" ''
    set -euo pipefail
    ts="$(date -Is)"
    hn="$(uname -n)"
    echo "$ts hello from $hn" >> ${lib.escapeShellArg cfg.logFile}
  '';

  defaultSchedule = "*-*-* *:*:0/${toString cfg.intervalSeconds}";
in
{
  options.services.homelab.hello = {
    enable = lib.mkEnableOption "Dead-simple hello task (via homelab-tasks framework)";

    intervalSeconds = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Append to the log file every N seconds (must evenly divide 60).";
    };

    logFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/log/homelab-hello.log";
      description = "Log file path.";
    };

    schedule = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional override for systemd OnCalendar. If null, uses '*-*-* *:*:0/N' derived from intervalSeconds.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.intervalSeconds > 0
          && cfg.intervalSeconds <= 60
          && (lib.mod 60 cfg.intervalSeconds) == 0;
        message =
          "services.homelab.hello.intervalSeconds must be 1..60 and evenly divide 60 (got ${toString cfg.intervalSeconds})";
      }
    ];

    services.homelab.tasks.enable = lib.mkDefault true;

    systemd.tmpfiles.rules = [
      "d ${builtins.dirOf cfg.logFile} 0755 root root -"
    ];

    services.homelab.tasks.tasks.hello = {
      description = "Homelab hello (append a line to ${cfg.logFile})";
      command = [ "${helloScript}" ];
      requiresNetworkOnline = false;
      schedule = if cfg.schedule == null then defaultSchedule else cfg.schedule;
      readWritePaths = [ (builtins.dirOf cfg.logFile) ];
      path = [ pkgs.coreutils ];
      taskLabel = "hello";
    };
  };
}
