{ immichUploadLocation, nasRootFolder, ...}:

{
  imports = [
    ../modules/docker/immich.nix
  ];

  homelab.managedDirectories.entries = {
    immichPostgres = {
      local = "/srv/immich/postgres";
      remote = "${nasRootFolder}/immich/postgres-volume";
      restore = false;
      backup = false;
      owner = "root";
      group = "root";
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
  };

  services.homelab.immichCompose = {
    enable = true;

    version = "v2.5.6";
    sopsFile = ../secrets/immich.yaml;

    uploadLocation = immichUploadLocation;
    dbDataLocation = "/srv/immich/postgres";
    redisDataLocation = "/srv/immich/redis";
    modelCacheLocation = "/srv/immich/model-cache";

    composeProjectName = "immich";
    dbUsername = "postgres";
    dbDatabaseName = "immich";
  };
}
