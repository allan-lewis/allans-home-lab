{ backupRemotePrefix, ... }:

let
  hostName = "cujo";
  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  imports = [
    ../../profiles/bare-metal
    ../../profiles/base
    ../../profiles/cloudflare
    ../../profiles/containers/it-tools
    ../../profiles/containers/nginx
    ../../profiles/containers/no-geeks-brewing
    ../../profiles/containers/twingate
    ../../profiles/devops
    ../../profiles/gatus
    ../../profiles/tailscale
    ../../profiles/traefik
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
    connectorKey = "modestAnteater";
    networkName = "allanshomelab";
  };

  services.homelab.cloudflaredTunnel = {
    enable = true;
  };

  system.stateVersion = "25.11";
}