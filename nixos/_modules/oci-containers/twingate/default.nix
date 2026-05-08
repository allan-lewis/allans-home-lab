{ config, lib, ... }:

let
  cfg = config.services.homelab.twingateConnector;
in
{
  options.services.homelab.twingateConnector = {
    enable = lib.mkEnableOption "Twingate connector";

    image = lib.mkOption {
      type = lib.types.str;
      description = "Twingate connector image.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Environment file containing Twingate connector settings/secrets.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers.twingate-connector = {
      image = cfg.image;
      environmentFiles = [
        cfg.environmentFile
      ];
    };
  };
}