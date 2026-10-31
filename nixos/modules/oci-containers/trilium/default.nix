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
      image = "docker.io/triliumnext/trilium:v0.106.1@sha256:871e9332d2e29a4ca29b3337ac7568235e0326584db8828ba86a3c0b8eacd7a7";

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
