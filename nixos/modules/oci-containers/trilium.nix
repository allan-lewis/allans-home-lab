{ config, nasRootFolder, ... }:

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

  virtualisation.oci-containers.containers.trilium = {
    image = "triliumnext/trilium:v0.101.3@sha256:86c1fd689b86881c4c80a651eff39b9090d129ab578879579febcf3111815b59";

    autoStart = true;

    ports = [ "8376:8080" ];

    volumes = [
      "/var/lib/trilium:/home/node/trilium-data"
    ];

    environment = {
      TZ = config.time.timeZone;
    };

    extraOptions = [ "--replace" ];
  };

  systemd.services.podman-trilium = {
    requires = [ "homelab-task-managed-state-restore.service" ];
    after = [ "homelab-task-managed-state-restore.service" ];
  };
}