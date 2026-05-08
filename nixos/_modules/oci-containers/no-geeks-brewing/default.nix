{ config, lib, ... }:

let
  cfg = config.services.homelab.noGeeksBrewing;
in
{
  options.services.homelab.noGeeksBrewing = {
    enable = lib.mkEnableOption "No Geeks Brewing container";

    image = lib.mkOption {
      type = lib.types.str;
      default = "allanelewis/ngb-go:v2026.04.0@sha256:32261fc7b13d58ccb6bf8f43ea7e07bd60a9213598a05d0ea462fc223bb83ec2";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8083;
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Environment file for the No Geeks Brewing container.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers.ngb = {
      image = cfg.image;

      ports = [
        "${toString cfg.port}:8080"
      ];

      environmentFiles = [
        cfg.environmentFile
      ];

      autoStart = true;
    };
  };
}