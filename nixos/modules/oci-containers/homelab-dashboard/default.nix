{ config, lib, ... }:

let
  cfg = config.services.homelab.dashboard;
in
{
  options.services.homelab.dashboard = {
    enable = lib.mkEnableOption "Home Lab Dashboard";

    image = lib.mkOption {
      type = lib.types.str;
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8976;
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Environment file for the Home Lab Dashboard container.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers.dashboard = {
      image = cfg.image;

      ports = [
        "${toString cfg.port}:3000"
      ];

      environmentFiles = [
        cfg.environmentFile
      ];

      autoStart = true;
    };
  };
}

