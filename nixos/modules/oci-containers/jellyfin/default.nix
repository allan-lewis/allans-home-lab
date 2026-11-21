{ config, mediaLibraryDir, ... }:

{
  virtualisation.oci-containers.containers.jellyfin = {
    image = "docker.io/jellyfin/jellyfin:12.4@sha256:fea863d0cd9ec445985d9c75fc6ed64e38a1d2766cf0c250a33d553f4fc1b771";

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
