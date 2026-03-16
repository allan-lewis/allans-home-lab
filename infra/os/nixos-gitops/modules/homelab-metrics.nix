{ config, lib, pkgs, ... }:

let
  cfg = config.services.homelab.metrics;
in
{
  options.services.homelab.metrics = {
    enable = lib.mkEnableOption "homelab metrics service";

    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/allanelewis/homelab-metrics:latest";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9102;
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.port ]; 
    
    virtualisation.oci-containers = {
      backend = "podman";

      containers.homelab-metrics = {
        image = cfg.image;
        autoStart = true;
        ports = [ "${toString cfg.port}:${toString cfg.port}/tcp" ];
        environment = cfg.environment;
        extraOptions = [
          "--replace"
        ];
      };
    };
  };
}