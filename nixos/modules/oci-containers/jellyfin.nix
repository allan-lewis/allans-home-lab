{ config, mediaLibraryDir, nasRootFolder, ... }:

{
  homelab.managedDirectories.entries = {
    jellyfinConfig = {
      local = "/srv/jellyfin/config";
      remote = "${nasRootFolder}/jellyfin/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    jellyfinCache = {
      local = "/srv/jellyfin/cache";
      remote = "${nasRootFolder}/jellyfin/cache";
      restore = false;
      backup = false;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };

  virtualisation.oci-containers.containers.jellyfin = {
    image = "jellyfin/jellyfin:2026041305@sha256:cd19378e55b75ebcee70a911acb077c50c2fba08e0c31f1a941d3adfcb4e1a0f";

    autoStart = true;

    ports = [ "8096:8096/tcp" ];

    volumes = [
      "/srv/jellyfin/config:/config"
      "/srv/jellyfin/cache:/cache"
      "${mediaLibraryDir}:/media-library:ro"
    ];

    environment = {
      JELLYFIN_PublishedServerUrl = "https://jellyfin.media.allanshomelab.com";
    };

    user = "${toString config.users.users.lab.uid}:${toString config.users.groups.lab.gid}";

    extraOptions = [ "--replace" ];
  };

  systemd.services.podman-jellyfin = {
    requires = [ "homelab-task-managed-state-restore.service" ];
    after = [ "homelab-task-managed-state-restore.service" ];
  };
}