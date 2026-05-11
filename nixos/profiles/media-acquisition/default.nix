{ remoteBackupRoot, ... }:

{
  imports = [
    ../../modules/oci-containers/r-stack
  ];

  _module.args = {
    mediaLibraryDir = "/data/media-library";

    bazarrConfigDir = "/etc/bazarr";
    lidarrConfigDir = "/etc/lidarr";
    prowlarrConfigDir = "/etc/prowlarr";
    radarrConfigDir = "/etc/radarr";
    sonarrConfigDir = "/etc/sonarr";
    transmissionConfigDir = "/etc/transmission";
    transmissionWatchDir = "/var/lib/transmission/watch";
  };

  homelab.managedDirectories.entries = {
    bazarrConfig = {
      local = "/etc/bazarr";
      remote = "${remoteBackupRoot}/bazarr/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    lidarrConfig = {
      local = "/etc/lidarr";
      remote = "${remoteBackupRoot}/lidarr/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    prowlarrConfig = {
      local = "/etc/prowlarr";
      remote = "${remoteBackupRoot}/prowlarr/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    radarrConfig = {
      local = "/etc/radarr";
      remote = "${remoteBackupRoot}/radarr/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    sonarrConfig = {
      local = "/etc/sonarr";
      remote = "${remoteBackupRoot}/sonarr/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    transmissionConfig = {
      local = "/etc/transmission";
      remote = "${remoteBackupRoot}/transmission/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    transmissionWatch = {
      local = "/var/lib/transmission/watch";
      remote = "${remoteBackupRoot}/transmission/watch";
      restore = false;
      backup = false;
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