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
    image = "triliumnext/trilium:v0.102.2@sha256:f1a2fd88e7032d60f863231ce94348e906bcd6a5fa043801badd5896c20c064d";

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