{ backupRemotePrefix, ... }:

let
  hostName = "cujo";
  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  imports = [
    ../../profiles/bare-metal
    ../../profiles/base
    ../../profiles/containers/it-tools
    ../../profiles/containers/nginx
    ../../profiles/containers/no-geeks-brewing
    ../../profiles/devops
    ../../profiles/tailscale
  ];

  networking.hostName = hostName;

  homelab.bareMetal.interface = "eth1";
  homelab.bareMetal.address = "192.168.86.219";

  homelab.managedDirectories.entries = {
    test_directory = {
      local = "/home/lab/backup-restore";
      remote = "${defaultRemoteNasPerHostBackupVolume}/backup-restore";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };

  system.stateVersion = "25.11";
}