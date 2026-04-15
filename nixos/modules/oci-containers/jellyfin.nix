{ nasRootFolder, ... }:

{
  homelab.managedDirectories.entries = {
    jellyfinConfig = {
      local = "/srv/jellyfin/config";
      remote = "${nasRootFolder}/jellyfin/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    jellyfinCache = {
      local = "/srv/jellyfin/cache";
      remote = "${nasRootFolder}/jellyfin/cache";
      restore = false;
      backup = false;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };
}