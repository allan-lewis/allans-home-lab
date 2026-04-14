{ nasRootFolder, ... }:

{
  homelab.managedDirectories.entries = {
    trilium = {
      local = "/var/lib/trilium";
      remote = "${nasRootFolder}/trilium";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };
}