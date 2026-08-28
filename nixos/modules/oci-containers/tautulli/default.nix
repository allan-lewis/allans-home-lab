{ config, ... }:

{
  virtualisation.oci-containers.containers.tautulli = {
    image = "ghcr.io/tautulli/tautulli:v2.18.1@sha256:6cb75e1ec2b934cb3e6cb4e049b0dcbf3fd175a405db40de29dd425cabe83cb2";

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