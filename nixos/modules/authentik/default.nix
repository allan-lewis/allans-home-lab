{ config, lib, pkgs, ... }:

let
  cfg = config.services.homelab.authentikCompose;
in
{
  imports = [
    ../docker
  ];
  
  options.services.homelab.authentikCompose = {
    enable = lib.mkEnableOption "Authentik via upstream Docker Compose";

    appName = lib.mkOption {
      type = lib.types.str;
      default = "authentik";
    };

    appDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/docker-compose/authentik";
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = "2025.10.3";
    };

    composeUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://docs.goauthentik.io/compose.yml";
    };

    httpPort = lib.mkOption {
      type = lib.types.port;
      default = 9180;
    };

    httpsPort = lib.mkOption {
      type = lib.types.port;
      default = 9143;
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Environment file for Authentik Docker Compose.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.environmentFile != null;
        message = "services.homelab.authentikCompose.environmentFile must be set when Authentik is enabled.";
      }
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.appDir} 0750 root root -"
    ];

    networking.firewall.allowedTCPPorts =
      lib.mkIf cfg.openFirewall [ cfg.httpPort cfg.httpsPort ];

    systemd.services.authentik-compose = {
      description = "Authentik Docker Compose stack";
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
        curl -fsSL ${lib.escapeShellArg cfg.composeUrl} -o ${cfg.appDir}/docker-compose.yml
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