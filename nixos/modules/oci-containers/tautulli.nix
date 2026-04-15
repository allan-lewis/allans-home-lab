{ config, nasRootFolder, ... }:

{
  homelab.managedDirectories.entries = {
    vaultwarden = {
      local = "/etc/tautulli";
      remote = "${nasRootFolder}/tautulli/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };

  virtualisation.oci-containers.containers.tautulli = {
    image = "ghcr.io/tautulli/tautulli:v2.17.0@sha256:1a82dcf8fcc715ad5f686fb04cad90969bab2dc28c971fd2d3089fbd9d467492";

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