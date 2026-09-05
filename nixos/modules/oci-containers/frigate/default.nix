{ config, remoteBackupRoot, ... }:

{
  virtualisation.oci-containers.containers.frigate = {
    image = "ghcr.io/blakeblackshear/frigate:0.17.2@sha256:d4351369984d4a9e2a49ac59736f6490856a7ea11f7790040746d21496967010";

    autoStart = true;

    ports = [
      "8971:8971/tcp" # Authenticated UI/API; use this from Traefik
      "8554:8554/tcp" # RTSP restreams
      "8555:8555/tcp" # WebRTC
      "8555:8555/udp" # WebRTC
    ];

    volumes = [
      "/srv/frigate/config:/config"
      "/srv/frigate/storage:/media/frigate"
      "/etc/localtime:/etc/localtime:ro"
    ];

    devices = [
      "/dev/dri:/dev/dri"
    ];

    environment = {
      TZ = config.time.timeZone;
    };

    extraOptions = [
      "--replace"
      "--shm-size=256m"
      "--tmpfs=/tmp/cache:rw,size=1000000000"
    ];
  };

  homelab.managedDirectories.entries = {
    frigate_config = {
      local = "/srv/frigate/config";
      remote = "${remoteBackupRoot}/frigate";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/frigate 0755 root root -"
    "d /srv/frigate/config 0755 root root -"
    "d /srv/frigate/storage 0755 root root -"
  ];

  systemd.services.podman-frigate = {
    requires = [
      "homelab-task-managed-state-restore.service"
    ];

    after = [
      "homelab-task-managed-state-restore.service"
    ];
  };
}
