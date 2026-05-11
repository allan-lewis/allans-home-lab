{ remoteBackupRoot, ... }:

{
  imports = [
    ../../modules/oci-containers/jellyfin
  ];

  homelab.managedDirectories.entries = {
    jellyfinConfig = {
      local = "/srv/jellyfin/config";
      remote = "${remoteBackupRoot}/jellyfin/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    jellyfinCache = {
      local = "/srv/jellyfin/cache";
      remote = "${remoteBackupRoot}/jellyfin/cache";
      restore = false;
      backup = false;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };
}