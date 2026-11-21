{ config, lib, ... }:

let
  cfg = config.services.homelab.trilium;
in
{
  options.services.homelab.trilium = {
    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = {
    virtualisation.oci-containers.containers.trilium = {
      image = "docker.io/triliumnext/trilium:v0.107.0@sha256:ac72ce66f562a1d6d1baedf7d5c1672f19c3ba1b048603e50c8fc8114c80c502";

      autoStart = true;

      ports = [ "8376:8080" ];

      volumes = [
        "/var/lib/trilium:/home/node/trilium-data"
      ];

      environment = {
        TZ = config.time.timeZone;
      };

      environmentFiles =
        lib.optional (cfg.environmentFile != null) cfg.environmentFile;

      extraOptions = [ "--replace" ];
    };

    systemd.services.podman-trilium = {
      requires = [ "homelab-task-managed-state-restore.service" ];
      after = [ "homelab-task-managed-state-restore.service" ];
    };
  };
}
