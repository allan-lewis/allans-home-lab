{ config, ... }:

{
  virtualisation.oci-containers.containers.trilium = {
    image = "triliumnext/trilium:v0.103.0@sha256:19935fd7fe459cf9f345046fc5e8a5e0f0118c60a9a7e676a09fe48ad249637a";

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