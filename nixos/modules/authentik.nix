{ config, lib, pkgs, ... }:

let
  cfg = config.services.homelab.authentikCompose;
in
{
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

    sopsFile = lib.mkOption {
      type = lib.types.path;
      default = ../secrets/authentik.yaml;
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;

    environment.systemPackages = with pkgs; [
      docker-compose
      curl
    ];

    sops.secrets.authentik_pg_pass = {
      sopsFile = cfg.sopsFile;
      key = "authentik/pg_pass";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    sops.secrets.authentik_secret_key = {
      sopsFile = cfg.sopsFile;
      key = "authentik/secret_key";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    sops.templates."authentik.env" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        AUTHENTIK_TAG=${cfg.version}
        COMPOSE_PORT_HTTP=${toString cfg.httpPort}
        COMPOSE_PORT_HTTPS=${toString cfg.httpsPort}
        PG_PASS=${config.sops.placeholder.authentik_pg_pass}
        AUTHENTIK_SECRET_KEY=${config.sops.placeholder.authentik_secret_key}
      '';
    };

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
        install -m 0400 ${config.sops.templates."authentik.env".path} ${cfg.appDir}/.env
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