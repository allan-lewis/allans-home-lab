{ hostIp4Address, hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/virtual-machine

    ../../profiles/immich
    ../../profiles/jellyfin
    ../../profiles/plex
    ../../profiles/tautulli
  ];

  _module.args = {
    #: needed by plex
    hostAddress = hostIp4Address;
    #: needed by jellyfin and plex
    mediaLibraryDir = "/data/media-library";
  };

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

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

  services.homelab.managedState.schedule = "*:40";
}
