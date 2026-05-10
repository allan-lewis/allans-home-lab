{ backupRoot, hostName, ... }:

{
  imports = [
    ../../../modules/virtual-machine

    ../../../profiles/immich
    ../../../profiles/jellyfin
    ../../../profiles/plex
    ../../../profiles/tautulli
  ];

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
  };

  networking.hostName = hostName;

  services.homelab.managedState.schedule  = "*:40";
}