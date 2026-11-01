{ config, mediaLibraryDir, ... }:

{
  virtualisation.oci-containers.containers.jellyfin = {
    image = "docker.io/jellyfin/jellyfin:12.4@sha256:7da5184caa38c553f219f6772476540081f392a68049e2b68c923f6daf877f8e";

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
