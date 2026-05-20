{ config, lib, pkgs, ... }:

let
  cfg = config.services.homelab.homepage;
in
{
  options.services.homelab.homepage = {
    enable = lib.mkEnableOption "Homepage container";

    image = lib.mkOption {
      type = lib.types.str;
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3007;
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/homepage/config";
    };

    allowedHosts = lib.mkOption {
      type = lib.types.str;
      description = "Comma-separated HOMEPAGE_ALLOWED_HOSTS value.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Environment file for Homepage.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers = {
      backend = "podman";

      containers.homepage = {
        image = cfg.image;
        autoStart = true;

        ports = [
          "${toString cfg.port}:3000"
        ];

        volumes = [
          "${cfg.configDir}:/app/config"
        ];

        environment = {
          HOMEPAGE_ALLOWED_HOSTS = cfg.allowedHosts;
        };

        environmentFiles = [
          cfg.environmentFile
        ];

        extraOptions = [
          "--pull=newer"
          "--replace"
          "--health-cmd=none"
        ];
      };
    };

    systemd.services.podman-homepage = {
      serviceConfig.ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p ${cfg.configDir}/logs"
      ];

      restartTriggers = [
        cfg.environmentFile
      ];
    };
  };
}