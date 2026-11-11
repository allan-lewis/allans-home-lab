{ config, ... }:

{
  virtualisation.oci-containers.containers.tautulli = {
    image = "ghcr.io/tautulli/tautulli:v2.19.1@sha256:4734b5d6afbac9f364bb93577135684d7c84a7be66b055f4f6b17d2bfc9721fa";

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