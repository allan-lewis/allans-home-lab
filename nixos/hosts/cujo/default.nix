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
    image = "twingate/connector:1.87.0@sha256:b348b79b6193062a40b8b6131beda8b2f42e64753e34a5908d93fc73acaeb503";
  };

  system.stateVersion = "25.11";
}