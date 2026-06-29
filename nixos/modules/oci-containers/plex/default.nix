{ config, mediaLibraryDir, hostAddress, ... }:

{
  virtualisation.oci-containers.containers.plex = {
    image = "lscr.io/linuxserver/plex:1.43.2@sha256:d00def5883ded31b4a5a2a33f5642883f044dc8715826b5cf9bc540d4e361ff3";

    autoStart = true;

    ports = [
      "32400:32400/tcp"
      "32410:32410/udp"
      "32411:32411/udp"
      "32412:32412/udp"
      "32413:32413/udp"
      "32414:32414/udp"
      "32469:32469/tcp"
      "1900:1900/udp"
      "3005:3005/tcp"
      "8324:8324/tcp"
    ];

    volumes = [
      "/srv/plex/config:/config"
      "/srv/plex/transcode:/transcode"
      "${mediaLibraryDir}:/media-library:ro"
    ];

    environment = {
      TZ = config.time.timeZone;
      PUID = toString config.users.users.lab.uid;
      PGID = toString config.users.groups.lab.gid;
      ADVERTISE_IP = "http://${hostAddress}:32400/";
    };

    extraOptions = [ "--replace" ];
  };

  systemd.services.podman-plex = {
    requires = [ "homelab-task-managed-state-restore.service" ];
    after = [ "homelab-task-managed-state-restore.service" ];
  };

}