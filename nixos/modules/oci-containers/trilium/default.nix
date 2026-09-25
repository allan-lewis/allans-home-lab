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
      image = "triliumnext/trilium:v0.106.0@sha256:24585639da9ba32c5701501c4075b00f4879f2a3eb996477a6dc577590f2d8f4";

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
