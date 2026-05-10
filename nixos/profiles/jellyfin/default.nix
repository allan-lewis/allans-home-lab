{ backupRoot, ... }:

{
  imports = [
    ../../modules/oci-containers/jellyfin
  ];

  homelab.managedDirectories.entries = {
    jellyfinConfig = {
      local = "/srv/jellyfin/config";
      remote = "${backupRoot}/jellyfin/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    jellyfinCache = {
      local = "/srv/jellyfin/cache";
      remote = "${backupRoot}/jellyfin/cache";
      restore = false;
      backup = false;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };
}