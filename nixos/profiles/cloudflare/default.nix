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

    tokenSopsFile = lib.mkOption {
      type = lib.types.path;
      default = ../../secrets/cloudflare.yaml;
      description = "SOPS file containing the Cloudflare tunnel token";
    };

    tokenSopsKey = lib.mkOption {
      type = lib.types.str;
      default = "cloudflared/tunnel_token";
      description = "Key within the SOPS file containing the tunnel token";
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
    sops.secrets.cloudflared_tunnel_token = {
      sopsFile = cfg.tokenSopsFile;
      key = cfg.tokenSopsKey;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    sops.templates."cloudflared.env" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        CLOUDFLARE_TUNNEL_TOKEN=${config.sops.placeholder.cloudflared_tunnel_token}
      '';
    };

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

        EnvironmentFile = config.sops.templates."cloudflared.env".path;

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