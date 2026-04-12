{ nasRootFolder, ... }:

{
  _module.args = {
    prowlarrConfigDir = "/etc/prowlarr";
  };

  imports = [
    ../../modules/r-stack.nix
  ];

  homelab.managedDirectories.entries = {
  bazaarConfig = {
    local = "/etc/bazarr";
    remote = "${nasRootFolder}/bazarr/config";
    restore = true;
    backup = true;
    owner = "lab";
    group = "lab";
    mode = "0755";
  };
  prowlarrConfig = {
    local = "/etc/prowlarr";
    remote = "${nasRootFolder}/prowlarr/config";
    restore = true;
    backup = true;
    owner = "lab";
    group = "lab";
    mode = "0755";
  };
};

fileSystems = {
  "/data/media-library" = {
    device = "192.168.86.220:/mnt/pool1/media-acquisition";
    fsType = "nfs";
    options = [
      "rw"
      "nofail"
      "_netdev"
      "x-systemd.requires=network-online.target"
      "x-systemd.after=network-online.target"
    ];
  };
};
}