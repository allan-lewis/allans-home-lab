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
      image = "triliumnext/trilium:v0.105.0@sha256:1d8492b82e461f9d8cba1acab2bf89d0182821318a1fc1277656e688a6fb4ee4";

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
