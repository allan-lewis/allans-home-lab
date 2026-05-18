{ config, lib, pkgs, ... }:

let
  cfg = config.services.homelab.authentikCompose;

  composeSeriesVersion = lib.versions.majorMinor cfg.version;

  resolvedComposeUrl =
    if cfg.composeUrl != null then
      cfg.composeUrl
    else if lib.versionAtLeast composeSeriesVersion "2026.2" then
      "https://goauthentik.io/version/${composeSeriesVersion}/lifecycle/container/compose.yml"
    else
      "https://goauthentik.io/version/${composeSeriesVersion}/docker-compose.yml";
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
    };

    composeUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional explicit Authentik Docker Compose URL.

        If unset, this module uses the minor-series compose URL derived from
        services.homelab.authentikCompose.version, for example:
        https://goauthentik.io/version/2025.12/docker-compose.yml
      '';
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
      "d ${cfg.appDir}/data 0750 root root -"
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
        install -d -m 0750 ${cfg.appDir}/data

        if [[ -d ${cfg.appDir}/media && ! -e ${cfg.appDir}/data/media ]]; then
          echo "Migrating Authentik media directory from ${cfg.appDir}/media to ${cfg.appDir}/data/media"
          mv ${cfg.appDir}/media ${cfg.appDir}/data/media
        elif [[ -d ${cfg.appDir}/media && -e ${cfg.appDir}/data/media ]]; then
          echo "WARNING: Both ${cfg.appDir}/media and ${cfg.appDir}/data/media exist; leaving both unchanged"
        fi

        curl -fsSL ${lib.escapeShellArg resolvedComposeUrl} -o ${cfg.appDir}/docker-compose.yml
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