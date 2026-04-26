{ config, backupRoot, ...}:

{
  imports = [
    ../../modules/docker/immich.nix
    ../../modules/postgres-db-backup.nix
  ];

  fileSystems = {
    "/data/immich" = {
      device = "192.168.86.220:/mnt/pool1/immich";
      fsType = "nfs";
      options = [
        "rw"
        "nofail"
        "_netdev"
        "x-systemd.requires=network-online.target"
        "x-systemd.after=network-online.target"
      ];
    };
  };

  homelab.managedDirectories.entries = {
    immichPostgres = {
      local = "/srv/immich/postgres";
      remote = "${backupRoot}/immich/postgres-volume";
      restore = false;
      backup = false;
      owner = "999";
      group = "999";
      mode = "0755";
    };
    immichRedis = {
      local = "/srv/immich/redis";
      remote = "${backupRoot}/immich/redis";
      restore = false;
      backup = false;
      owner = "root";
      group = "root";
      mode = "0755";
    };
    immichModelCache = {
      local = "/srv/immich/model-cache";
      remote = "${backupRoot}/immich/model-cache";
      restore = false;
      backup = false;
      owner = "root";
      group = "root";
      mode = "0755";
    };
    immichPostgresDbDumps = {
      local = "/var/lib/postgres-db-dumps";
      remote = "${backupRoot}/immich/db-dumps";
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
    sopsFile = ./secrets/immich.yaml;

    uploadLocation = "/data/immich";
    dbDataLocation = "/srv/immich/postgres";
    redisDataLocation = "/srv/immich/redis";
    modelCacheLocation = "/srv/immich/model-cache";

    composeProjectName = "immich";
    dbUsername = "postgres";
    dbDatabaseName = "immich";
  };

  sops.secrets."immich/db_password" = {
    sopsFile = ./secrets/immich.yaml;
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
