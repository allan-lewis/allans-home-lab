{ backupRemotePrefix, lib, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/patricia.toml);
  hostName = inventoryConfig.hostname;
  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  imports = [
    ../../profiles/base
    ../../profiles/virtual-machine
  ];

  networking.hostName = hostName;

  homelab.managedDirectories.entries = {
    prowlarrConfig = {
      local = "/etc/prowlarr";
      remote = "${defaultRemoteNasPerHostBackupVolume}/prowlarr/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };

  fileSystems = {
    "/data/media-library" = {
      device = "192.168.86.220:/mnt/pool1/media-acquisition";
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