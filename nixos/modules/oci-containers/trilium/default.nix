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
      image = "triliumnext/trilium:v0.104.1@sha256:1c5ef078d61c57be26a6fd018384f0a4b039cbfa1c49b207b91e909da956f090";

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
