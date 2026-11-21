{ config, ... }:

{
  virtualisation.oci-containers.containers.tautulli = {
    image = "ghcr.io/tautulli/tautulli:v2.19.1@sha256:239cd6dbc429a0eb441bdf88a7a015871e2d4d6e02b6e6039af30c0487528a8e";

    autoStart = true;

    ports = [ "8181:8181" ];

    volumes = [
      "/etc/tautulli:/config"
    ];

    environment = {
      PUID = toString config.users.users.lab.uid;
      PGID = toString config.users.groups.lab.gid;
      TZ = config.time.timeZone;
    };

    extraOptions = [ "--replace" ];
  };

  systemd.services.podman-tautulli = {
    requires = [ "homelab-task-managed-state-restore.service" ];
    after = [ "homelab-task-managed-state-restore.service" ];
  };
}