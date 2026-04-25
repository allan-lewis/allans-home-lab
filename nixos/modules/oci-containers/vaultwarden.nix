{ config, nasRootFolder, ... }:

{
  homelab.managedDirectories.entries = {
    vaultwarden = {
      local = "/var/lib/vaultwarden";
      remote = "${nasRootFolder}/vaultwarden";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };

  sops.secrets.vaultwarden_env = {
    sopsFile = ../../secrets/vaultwarden.env;
    format = "dotenv";
    key = "";
  };

  virtualisation.oci-containers.containers.vaultwarden = {
    image = "vaultwarden/server:1.35.8@sha256:c4f6056fe0c288a052a223cecd263a90d1dda1a0177bb5b054a363a6c7b211d9";

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