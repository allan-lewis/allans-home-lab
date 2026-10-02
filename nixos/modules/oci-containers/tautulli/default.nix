{ config, ... }:

{
  virtualisation.oci-containers.containers.tautulli = {
    image = "ghcr.io/tautulli/tautulli:v2.18.2@sha256:6681d91b75ecfedfb9df4b2e251345a89f79a511aa14dade1193320e38c892e1";

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