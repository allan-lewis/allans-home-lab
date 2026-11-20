{ config, remoteBackupRoot, frigateStorageDir, ... }:

{
  virtualisation.oci-containers.containers.frigate = {
    image = "ghcr.io/blakeblackshear/frigate:0.18.3@sha256:52ee4a7b4aa403347c1f31974d4faafc7157f97933c08c905c08ec6599f4f27a";

    autoStart = true;

    ports = [
      "8971:8971/tcp" # Authenticated UI/API; use this from Traefik
      "8554:8554/tcp" # RTSP restreams
      "8555:8555/tcp" # WebRTC
      "8555:8555/udp" # WebRTC
    ];

    volumes = [
      "/srv/frigate/config:/config"
      "${frigateStorageDir}:/media/frigate"
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
    "d /data/frigate 0755 root root -"
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
