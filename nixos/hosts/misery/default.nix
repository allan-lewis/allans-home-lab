{ backupRemotePrefix, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/misery.toml);
  hostName = inventoryConfig.hostname;
  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  _module.args = {
    hostIp = "192.168.86.227";
    immichUploadLocation = "/data/immich";
    mediaLibraryDir = "/data/media-library";
    nasRootFolder = defaultRemoteNasPerHostBackupVolume;
  };
  
  imports = [
    ../../profiles/base
    ../../profiles/immich.nix
    ../../profiles/virtual-machine

    ../../modules/oci-containers/jellyfin.nix
    ../../modules/oci-containers/plex.nix
    ../../modules/oci-containers/tautulli.nix
  ];

  networking.hostName = hostName;

  homelab.managedDirectories.entries = {
    immichPostgresDbDumps = {
      local = "/var/lib/postgres-db-dumps";
      remote = "${defaultRemoteNasPerHostBackupVolume}/immich/db-dumps";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };

  fileSystems = {
    "/data/media-library" = {
      device = "192.168.86.220:/mnt/pool1/media-library";
      fsType = "nfs";
      options = [
        "ro"
        "nofail"
        "_netdev"
        "x-systemd.requires=network-online.target"
        "x-systemd.after=network-online.target"
      ];
    };
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

  system.stateVersion = "25.11";
}