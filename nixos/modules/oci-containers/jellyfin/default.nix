{ config, mediaLibraryDir, ... }:

{
  virtualisation.oci-containers.containers.jellyfin = {
    image = "jellyfin/jellyfin:12.3@sha256:720ad28968e040f1ea049749f4ce546b28c7251244a6eb8aacf9147d8afbc24d";

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
