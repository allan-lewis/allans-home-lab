{ backupRoot, hostName, ... }:

{
  imports = [
    ../immich
    ../virtual-machine.nix

    ../../modules/oci-containers/jellyfin.nix
    ../../modules/oci-containers/plex.nix
    ../../modules/oci-containers/tautulli.nix
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

  homelab.managedStateSchedule = "*:40";
}