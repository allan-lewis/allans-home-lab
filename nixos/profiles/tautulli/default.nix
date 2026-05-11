{ remoteBackupRoot, ... }:

{
  imports = [
    ../../modules/oci-containers/tautulli
  ];

  homelab.managedDirectories.entries = {
    vaultwarden = {
      local = "/etc/tautulli";
      remote = "${remoteBackupRoot}/tautulli/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };
}