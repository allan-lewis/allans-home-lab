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
}

