{ config, mediaLibraryDir, backupRoot, ... }:

{
  homelab.managedDirectories.entries = {
    jellyfinConfig = {
      local = "/srv/jellyfin/config";
      remote = "${backupRoot}/jellyfin/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    jellyfinCache = {
      local = "/srv/jellyfin/cache";
      remote = "${backupRoot}/jellyfin/cache";
      restore = false;
      backup = false;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };

  virtualisation.oci-containers.containers.jellyfin = {
    image = "jellyfin/jellyfin:2026041305@sha256:7381f54b16aa544e02d33193ae43fbe0d1bc7470e179d576ee5d8d874e4952ca";

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