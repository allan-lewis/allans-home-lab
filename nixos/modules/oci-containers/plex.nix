{ config, nasRootFolder, mediaLibraryDir, hostIp, ... }:

{
  homelab.managedDirectories.entries = {
    plexConfig = {
      local = "/srv/plex/config";
      remote = "${nasRootFolder}/plex/config";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
    plexTranscode = {
      local = "/srv/plex/transcode";
      remote = "${nasRootFolder}/plex/transcode";
      restore = false;
      backup = false;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };

  virtualisation.oci-containers.containers.plex = {
    image = "lscr.io/linuxserver/plex:1.43.1@sha256:eb44f9abb0b83854f3f0704e3e806366690c68bf383805b7870152d82dbd4cd1";

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
      ADVERTISE_IP = "http://${hostIp}:32400/";
    };

    extraOptions = [ "--replace" ];
  };

  systemd.services.podman-plex = {
    requires = [ "homelab-task-managed-state-restore.service" ];
    after = [ "homelab-task-managed-state-restore.service" ];
  };

}