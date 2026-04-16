{ config, immichUploadLocation, nasRootFolder, ...}:

{
  imports = [
    ../modules/docker/immich.nix
    ../modules/postgres-db-backup.nix
  ];

  homelab.managedDirectories.entries = {
    immichPostgres = {
      local = "/srv/immich/postgres";
      remote = "${nasRootFolder}/immich/postgres-volume";
      restore = false;
      backup = false;
      owner = "999";
      group = "999";
      mode = "0755";
    };
    immichRedis = {
      local = "/srv/immich/redis";
      remote = "${nasRootFolder}/immich/redis";
      restore = false;
      backup = false;
      owner = "root";
      group = "root";
      mode = "0755";
    };
    immichModelCache = {
      local = "/srv/immich/model-cache";
      remote = "${nasRootFolder}/immich/model-cache";
      restore = false;
      backup = false;
      owner = "root";
      group = "root";
      mode = "0755";
    };
    immichPostgresDbDumps = {
      local = "/var/lib/postgres-db-dumps";
      remote = "${nasRootFolder}/immich/db-dumps";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };

  services.homelab.immichCompose = {
    enable = true;

    version = "v2.7.5";
    sopsFile = ../secrets/immich.yaml;

    uploadLocation = immichUploadLocation;
    dbDataLocation = "/srv/immich/postgres";
    redisDataLocation = "/srv/immich/redis";
    modelCacheLocation = "/srv/immich/model-cache";

    composeProjectName = "immich";
    dbUsername = "postgres";
    dbDatabaseName = "immich";
  };

  sops.secrets."immich/db_password" = {
    sopsFile = ../secrets/immich.yaml;
  };

  services.homelab.postgresDbBackup = {
    enable = true;
    schedule = "*-*-* 06:10:00";

    db = "immich";
    user = "postgres";
    container = "immich_postgres";
    extraArgs = "";
    passwordFile = config.sops.secrets."immich/db_password".path;
  };
}
