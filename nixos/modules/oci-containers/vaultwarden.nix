{ config, ... }:

{
  sops.secrets.vaultwarden_env = {
    sopsFile = ./secrets/vaultwarden/vaultwarden.env;
    format = "dotenv";
    key = "";
  };

  virtualisation.oci-containers.containers.vaultwarden = {
    image = "vaultwarden/server:1.35.4@sha256:73f9a159204917843875eb12c5ccd9acbcbf8f15ff7f2ce43cf912eef9f97eff";

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