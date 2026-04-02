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
    image = "twingate/connector:1.85.0@sha256:5e126d3ce36aa20b8977bab0b7e3da90ba1e10476234020a81cbdaf02781136b";
  };

  system.stateVersion = "25.11";
}