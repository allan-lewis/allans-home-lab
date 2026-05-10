{ backupRoot, config, ... }:

{
  imports = [
    ../../modules/immich
  ];

  #: load db password from a sops secret
  sops.secrets.immich_db_password = {
    sopsFile = ./immich.yaml;
    key = "immich/db_password";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  #: render Immich compose env file
  sops.templates."immich.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      IMMICH_VERSION=v2.7.5
      UPLOAD_LOCATION=/data/immich
      DB_DATA_LOCATION=/srv/immich/postgres
      REDIS_DATA_LOCATION=/srv/immich/redis
      MODEL_CACHE_LOCATION=/srv/immich/model-cache
      COMPOSE_PROJECT_NAME=immich
      DB_USERNAME=postgres
      DB_DATABASE_NAME=immich
      DB_PASSWORD=${config.sops.placeholder.immich_db_password}
    '';
  };

  #: run the immich docker compose service
  services.homelab.immichCompose = {
    enable = true;
    version = "v2.7.5";
    environmentFile = config.sops.templates."immich.env".path;
  };

  #: setup managed directories
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

  #: mount the nfs filesystem
  fileSystems."/data/immich" = {
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

  #: schedule database backups
  services.homelab.postgresDbBackup = {
    enable = true;
    schedule = "*-*-* 06:10:00";

    db = "immich";
    user = "postgres";
    container = "immich_postgres";
    extraArgs = "";
    passwordFile = config.sops.secrets.immich_db_password.path;
  };
}