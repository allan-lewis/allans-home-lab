{ config, ... }:

{
  virtualisation.oci-containers.containers.trilium = {
    image = "triliumnext/trilium:v0.102.2@sha256:436a4095a46150247de754aef32384045824f5f9279d535fbdaa2a4c57e84ba8";

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