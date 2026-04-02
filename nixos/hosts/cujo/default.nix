{ backupRemotePrefix, ... }:

let
  hostName = "cujo";
  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  imports = [
    ../../profiles/bare-metal
    ../../profiles/base
    ../../profiles/containers/homepage
    ../../profiles/containers/it-tools
    ../../profiles/containers/nginx
    ../../profiles/containers/no-geeks-brewing
    ../../profiles/containers/twingate
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

  services.homelab.twingateConnector = {
    enable = true;
    connectorKey = "valiantStingray";
    networkName = "allanshomelab";
    image = "twingate/connector:1.86.0@sha256:0a74cb9ffcf00e02d22199c8b9b53e3d02aa577d10615542bc3138acf7bb68f5";
  };

  system.stateVersion = "25.11";
}