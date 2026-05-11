{ config, lib, ... }:

let
  cfg = config.services.homelab.vaultwarden;
in
{
  options.services.homelab.vaultwarden = {
    enable = lib.mkEnableOption "Vaultwarden container";

    image = lib.mkOption {
      type = lib.types.str;
      default = "vaultwarden/server:1.35.8@sha256:1e6ebcede9be39fc1a7617eec4c984899edd954c09bd651b121cd89732e7aef4";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 35550;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/vaultwarden";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Environment file for Vaultwarden.";
    };

    signupsAllowed = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.vaultwarden = {
      image = cfg.image;

      autoStart = true;

      ports = [ "${toString cfg.port}:80" ];

      volumes = [
        "${cfg.dataDir}:/data"
      ];

      environmentFiles = [
        cfg.environmentFile
      ];

      environment = {
        SIGNUPS_ALLOWED = if cfg.signupsAllowed then "true" else "false";
      };

      extraOptions = [ "--replace" ];
    };

    systemd.services.podman-vaultwarden = {
      requires = [ "homelab-task-managed-state-restore.service" ];
      after = [ "homelab-task-managed-state-restore.service" ];
    };
  };
}