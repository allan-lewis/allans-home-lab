{ hostIp4Address, hostIp4Gateway, hostInterface, hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/bare-metal
    ../../modules/oci-containers/frigate
    ../../modules/oci-containers/it-tools
    ../../modules/oci-containers/nginx
    ../../modules/tailscale

    ../../profiles/jellyfin
    ../../profiles/tautulli
    ../../profiles/trilium
    ../../profiles/twingate
  ];

  _module.args = {
    #: needed by plex
    hostAddress = hostIp4Address;
    #: needed by jellyfin and plex
    mediaLibraryDir = "/data/media-library";
  };

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostIp4Address;
    gateway = hostIp4Gateway;
  };

  services.homelab.managedState.schedule = "*:10";

  homelab.twingate = {
    enable = true;
    connectorName = "valiantStingray";
  };

  fileSystems = {
    "/data/media-library" = {
      device = "pennywise.ip.allanshomelab.com:/mnt/pool1/media-library";
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

}
