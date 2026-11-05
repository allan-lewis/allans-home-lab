{ config, lib, ... }:

let
  cfg = config.services.homelab.cloudflaredTunnel;
in
{
  options.services.homelab.cloudflaredTunnel = {
    enable = lib.mkEnableOption "Cloudflare Tunnel";

    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/cloudflare/cloudflared:2026.10.7@sha256:4955524aeaa379e154023d5a027c250f7b35041a2e7e950cf13f144bc9b9c5ba";
      description = "cloudflared image to run.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Environment file containing TUNNEL_TOKEN.";
    };

    metricsPort = lib.mkOption {
      type = lib.types.port;
      default = 2000;
      description = "Port for the cloudflared Prometheus metrics listener";
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
    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers.cloudflared-tunnel = {
      image = cfg.image;
      autoStart = true;

      environmentFiles = [ cfg.environmentFile ];

      cmd = [
        "tunnel"
        "--no-autoupdate"
        "--metrics"
        "0.0.0.0:${toString cfg.metricsPort}"
        "run"
      ] ++ cfg.extraArgs;

      ports = [ "${toString cfg.metricsPort}:${toString cfg.metricsPort}/tcp" ];

      extraOptions = [ "--replace" ];
    };

    networking.firewall.allowedTCPPorts =
      lib.mkIf cfg.openFirewall [ cfg.metricsPort ];
  };
}
