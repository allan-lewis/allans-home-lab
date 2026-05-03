{ config, ... }:

{
  sops.secrets.vaultwarden_env = {
    sopsFile = ./secrets/vaultwarden/vaultwarden.env;
    format = "dotenv";
    key = "";
  };

  virtualisation.oci-containers.containers.vaultwarden = {
    image = "vaultwarden/server:1.36.0@sha256:ae4bcc7bf8ac933eb1854fe3b849c74bd94dffef56c2490f9fdeac0c3f916d92";

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