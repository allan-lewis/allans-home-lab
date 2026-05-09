{ config, lib, pkgs, ... }:

let
  cfg = config.services.homelab.immichCompose;

  composeUrl =
    if cfg.composeUrl != null then
      cfg.composeUrl
    else
      "https://github.com/immich-app/immich/releases/download/${cfg.version}/docker-compose.yml";
in
{
  options.services.homelab.immichCompose = {
    enable = lib.mkEnableOption "Immich via upstream Docker Compose";

    appName = lib.mkOption {
      type = lib.types.str;
      default = "immich";
    };

    appDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/docker-compose/immich";
    };

    version = lib.mkOption {
      type = lib.types.str;
    };

    composeUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://github.com/immich-app/immich/releases/download/v1.132.3/docker-compose.yml";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Environment file for the Immich Docker Compose stack.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 2283;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.environmentFile != null;
        message = "services.homelab.immichCompose.environmentFile must be set when Immich is enabled.";
      }
    ];

    virtualisation.docker.enable = true;

    users.users.lab.extraGroups = [ "docker" ];

    environment.systemPackages = with pkgs; [
      docker-compose
      curl
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.appDir} 0750 root root -"
    ];

    networking.firewall.allowedTCPPorts =
      lib.mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.immich-compose = {
      description = "Immich Docker Compose stack";
      wantedBy = [ "multi-user.target" ];
      after = [ "docker.service" "network-online.target" ];
      wants = [ "docker.service" "network-online.target" ];
      restartIfChanged = true;

      path = with pkgs; [
        docker-compose
        curl
        coreutils
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = cfg.appDir;
      };

      preStart = ''
        install -d -m 0750 ${cfg.appDir}
        curl -fsSL ${lib.escapeShellArg composeUrl} -o ${cfg.appDir}/docker-compose.yml
        install -m 0400 ${cfg.environmentFile} ${cfg.appDir}/.env
      '';

      script = ''
        docker-compose -f ${cfg.appDir}/docker-compose.yml up -d
      '';

      preStop = ''
        docker-compose -f ${cfg.appDir}/docker-compose.yml down
      '';
    };
  };
}