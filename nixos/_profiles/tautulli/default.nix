{ backupRoot, ... }:

{
  imports = [
    ../../_modules/oci-containers/tautulli
  ];

  homelab.managedDirectories.entries = {
    vaultwarden = {
      local = "/etc/tautulli";
      remote = "${backupRoot}/tautulli/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };
}