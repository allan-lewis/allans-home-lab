{ backupRoot, ... }:

{
  imports = [
    ../../modules/oci-containers/plex
  ];

  homelab.managedDirectories.entries = {
    plexConfig = {
      local = "/srv/plex/config";
      remote = "${backupRoot}/plex/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    plexTranscode = {
      local = "/srv/plex/transcode";
      remote = "${backupRoot}/plex/transcode";
      restore = false;
      backup = false;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };
}