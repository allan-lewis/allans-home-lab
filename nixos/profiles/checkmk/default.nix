{ remoteBackupRoot, config, ... }:

{
  imports = [
    ../../modules/oci-containers/checkmk
  ];

  homelab.managedDirectories.entries = {
    vaultwarden = {
      local = config.services.checkmk.dataDir;
      remote = "${remoteBackupRoot}/checkmk";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };
}

