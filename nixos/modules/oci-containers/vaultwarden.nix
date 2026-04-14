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
    image = "vaultwarden/server:1.35.4@sha256:43498a94b22f9563f2a94b53760ab3e710eefc0d0cac2efda4b12b9eb8690664";

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