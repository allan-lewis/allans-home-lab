{ defaultNasHost, ... }:

{
  fileSystems = {
    "/data/media-library" = {
      device = "${defaultNasHost}:/mnt/pool1/media-library";
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
