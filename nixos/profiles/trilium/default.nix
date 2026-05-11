{ remoteBackupRoot, ... }:

{
  imports = [
    ../../modules/oci-containers/trilium
  ];

  homelab.managedDirectories.entries = {
    trilium = {
      local = "/var/lib/trilium";
      remote = "${remoteBackupRoot}/trilium";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };
}