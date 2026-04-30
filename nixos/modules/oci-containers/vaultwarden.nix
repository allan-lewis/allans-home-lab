{ config, ... }:

{
  sops.secrets.vaultwarden_env = {
    sopsFile = ./secrets/vaultwarden/vaultwarden.env;
    format = "dotenv";
    key = "";
  };

  virtualisation.oci-containers.containers.vaultwarden = {
    image = "vaultwarden/server:1.35.8@sha256:1e6ebcede9be39fc1a7617eec4c984899edd954c09bd651b121cd89732e7aef4";

    autoStart = true;

    ports = [ "35550:80" ];

    volumes = [
      "/var/lib/vaultwarden:/data"
    ];

    environmentFiles = [
      config.sops.secrets.vaultwarden_env.path
    ];

    environment = {
      SIGNUPS_ALLOWED = "false";
    };

    extraOptions = [ "--replace" ];
  };

  systemd.services.podman-vaultwarden = {
    requires = [ "homelab-task-managed-state-restore.service" ];
    after = [ "homelab-task-managed-state-restore.service" ];
  };
}