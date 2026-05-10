{ config, lib, pkgs, ... }:

let
  cfg = config.services.homelab.cloudflaredTunnel;
in
{
  options.services.homelab.cloudflaredTunnel = {
    enable = lib.mkEnableOption "Cloudflare Tunnel";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.cloudflared;
      description = "cloudflared package to run";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Environment file containing CLOUDFLARE_TUNNEL_TOKEN.";
    };

    metricsAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0:2000";
      description = "Address for the cloudflared Prometheus metrics listener";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the metrics port in the firewall";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments to append to `cloudflared tunnel run`";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.environmentFile != null;
        message = "services.homelab.cloudflaredTunnel.environmentFile must be set when Cloudflare Tunnel is enabled.";
      }
    ];

    networking.firewall.allowedTCPPorts =
      lib.mkIf cfg.openFirewall [ 2000 ];

    systemd.services.cloudflared-tunnel = {
      description = "Cloudflare Tunnel";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      restartIfChanged = true;

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";

        EnvironmentFile = cfg.environmentFile;

        ExecStart = pkgs.writeShellScript "cloudflared-tunnel-start" ''
          set -euo pipefail
          exec ${lib.getExe cfg.package} \
            tunnel \
            --no-autoupdate \
            --metrics ${lib.escapeShellArg cfg.metricsAddress} \
            run \
            --token "$CLOUDFLARE_TUNNEL_TOKEN" \
            ${lib.escapeShellArgs cfg.extraArgs}
        '';

        DynamicUser = true;
        StateDirectory = "cloudflared";
        WorkingDirectory = "/var/lib/cloudflared";

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
        SystemCallArchitectures = "native";
      };
    };
  };
}