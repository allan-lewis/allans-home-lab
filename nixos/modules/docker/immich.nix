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

    uploadLocation = lib.mkOption {
      type = lib.types.str;
      default = "/data/immich";
    };

    dbDataLocation = lib.mkOption {
      type = lib.types.str;
      default = "/srv/immich/postgres";
    };

    redisDataLocation = lib.mkOption {
      type = lib.types.str;
      default = "/srv/immich/redis";
    };

    modelCacheLocation = lib.mkOption {
      type = lib.types.str;
      default = "/srv/immich/model-cache";
    };

    composeProjectName = lib.mkOption {
      type = lib.types.str;
      default = "immich";
    };

    dbUsername = lib.mkOption {
      type = lib.types.str;
      default = "postgres";
    };

    dbDatabaseName = lib.mkOption {
      type = lib.types.str;
      default = "immich";
    };

    sopsFile = lib.mkOption {
      type = lib.types.path;
      default = ../secrets/immich.yaml;
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
    virtualisation.docker.enable = true;

    environment.systemPackages = with pkgs; [
      docker-compose
      curl
    ];

    sops.secrets.immich_db_password = {
      sopsFile = cfg.sopsFile;
      key = "immich/db_password";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    sops.templates."immich.env" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        IMMICH_VERSION=${cfg.version}
        UPLOAD_LOCATION=${cfg.uploadLocation}
        DB_DATA_LOCATION=${cfg.dbDataLocation}
        REDIS_DATA_LOCATION=${cfg.redisDataLocation}
        MODEL_CACHE_LOCATION=${cfg.modelCacheLocation}
        COMPOSE_PROJECT_NAME=${cfg.composeProjectName}
        DB_USERNAME=${cfg.dbUsername}
        DB_DATABASE_NAME=${cfg.dbDatabaseName}
        DB_PASSWORD=${config.sops.placeholder.immich_db_password}
      '';
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.appDir} 0750 root root -"
      "d ${cfg.uploadLocation} 0750 root root -"
      "d ${cfg.dbDataLocation} 0750 root root -"
      "d ${cfg.redisDataLocation} 0750 root root -"
      "d ${cfg.modelCacheLocation} 0750 root root -"
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
        install -m 0400 ${config.sops.templates."immich.env".path} ${cfg.appDir}/.env
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