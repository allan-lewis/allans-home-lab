{ config, pkgs, 
  mediaLibraryDir, 
  bazarrConfigDir, 
  lidarrConfigDir, 
  prowlarrConfigDir, 
  radarrConfigDir,
  sonarrConfigDir,
  transmissionConfigDir, transmissionWatchDir,
  ... 
}:

{
  virtualisation.oci-containers.containers.prowlarr = {
    image = "ghcr.io/linuxserver/prowlarr:2.3.5@sha256:b4204e18666179472225935b443a99cf6c66dcb7bbc2d35034427a3851f13135";

    autoStart = true;

    ports = [ "9696:9696" ];

    volumes = [
      "${prowlarrConfigDir}:/config"
    ];

    environment = {
      PUID = toString config.users.users.lab.uid;
      PGID = toString config.users.groups.lab.gid;
      TZ = config.time.timeZone;
    };

    networks = [ "media" ];

    extraOptions = [ "--replace" ];
  };

  virtualisation.oci-containers.containers.bazarr = {
    image = "ghcr.io/linuxserver/bazarr:1.5.6@sha256:cb57afc3bd35558e1e7062658f9d4d18a0b4c474f10afe55f0ccfd867025f24f";

    autoStart = true;

    ports = [ "6767:6767" ];

    volumes = [
      "${bazarrConfigDir}:/config"
    ];

    environment = {
      PUID = toString config.users.users.lab.uid;
      PGID = toString config.users.groups.lab.gid;
      TZ = config.time.timeZone;
    };

    networks = [ "media" ];

    extraOptions = [ "--replace" ];
  };

  virtualisation.oci-containers.containers.lidarr = {
    image = "ghcr.io/linuxserver/lidarr:3.1.0@sha256:e9a275176e8158638395cc8574b02b7695006f70bde48830a09fa6ab5b6775df";

    autoStart = true;

    ports = [ "8686:8686" ];

    volumes = [
      "${lidarrConfigDir}:/config"
      "${mediaLibraryDir }/downloads:/downloads"
      "${mediaLibraryDir }/music:/music"
    ];

    environment = {
      PUID = toString config.users.users.lab.uid;
      PGID = toString config.users.groups.lab.gid;
      TZ = config.time.timeZone;
    };

    networks = [ "media" ];

    extraOptions = [ "--replace" ];
  };

  virtualisation.oci-containers.containers.radarr = {
    image = "ghcr.io/linuxserver/radarr:6.1.1@sha256:659e5f20500948b1491f31dd85c6f99a43508ce3e46595793e1e15aa955bf6d7";

    autoStart = true;

    ports = [ "7878:7878" ];

    volumes = [
      "${radarrConfigDir}:/config"
      "${mediaLibraryDir }/downloads:/downloads"
      "${mediaLibraryDir }/movies:/movies"
    ];

    environment = {
      PUID = toString config.users.users.lab.uid;
      PGID = toString config.users.groups.lab.gid;
      TZ = config.time.timeZone;
    };

    networks = [ "media" ];

    extraOptions = [ "--replace" ];
  };

  virtualisation.oci-containers.containers.sonarr = {
    image = "ghcr.io/linuxserver/sonarr:4.0.17@sha256:3580aec3802c915f0f819a88d5099abce61734b925732b8393d176b5dc561020";

    autoStart = true;

    ports = [ "8989:8989" ];

    volumes = [
      "${sonarrConfigDir}:/config"
      "${mediaLibraryDir }/downloads:/downloads"
      "${mediaLibraryDir }/tv:/tv"
    ];

    environment = {
      PUID = toString config.users.users.lab.uid;
      PGID = toString config.users.groups.lab.gid;
      TZ = config.time.timeZone;
    };

    networks = [ "media" ];

    extraOptions = [ "--replace" ];
  };

  virtualisation.oci-containers.containers.transmission = {
    image = "ghcr.io/linuxserver/transmission:4.1.1@sha256:bf92decd1387527be35139dc03e2d8c2c078a727f927ab474aef0f21f684107a";

    autoStart = true;

    ports = [ "9091:9091" ];

    volumes = [
      "${transmissionConfigDir}:/config"
      "${transmissionWatchDir}:/watch"
      "${mediaLibraryDir }/downloads:/downloads"
    ];

    environment = {
      PUID = toString config.users.users.lab.uid;
      PGID = toString config.users.groups.lab.gid;
      TZ = config.time.timeZone;
    };

    networks = [ "media" ];

    extraOptions = [ "--replace" ];
  };

  systemd.services.podman-network-media = {
    description = "Create podman network: media";
    wantedBy = [ "multi-user.target" ];
    before = [ "podman-bazarr.service"
               "podman-lidarr.service"
               "podman-prowlarr.service"
               "podman-radarr.service"
               "podman-sonarr.service"
               "podman-transmission.service" 
    ];
    requires = [ "homelab-task-managed-state-restore.service" ];
    after = [ "homelab-task-managed-state-restore.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.runtimeShell} -c '${pkgs.podman}/bin/podman network exists media || ${pkgs.podman}/bin/podman network create media'";
    };
  };

  systemd.services.podman-bazarr = {
    requires = [
      "podman-network-media.service"
      "homelab-task-managed-state-restore.service"
    ];
    after = [
      "podman-network-media.service"
      "homelab-task-managed-state-restore.service"
    ];
  };

  systemd.services.podman-lidarr = {
    requires = [
      "podman-network-media.service"
      "homelab-task-managed-state-restore.service"
    ];
    after = [
      "podman-network-media.service"
      "homelab-task-managed-state-restore.service"
    ];
  };

  systemd.services.podman-prowlarr = {
    requires = [
      "podman-network-media.service"
      "homelab-task-managed-state-restore.service"
    ];
    after = [
      "podman-network-media.service"
      "homelab-task-managed-state-restore.service"
    ];
  };

  systemd.services.podman-radarr = {
    requires = [
      "podman-network-media.service"
      "homelab-task-managed-state-restore.service"
    ];
    after = [
      "podman-network-media.service"
      "homelab-task-managed-state-restore.service"
    ];
  };

  systemd.services.podman-sonarr = {
    requires = [
      "podman-network-media.service"
      "homelab-task-managed-state-restore.service"
    ];
    after = [
      "podman-network-media.service"
      "homelab-task-managed-state-restore.service"
    ];
  };

  systemd.services.podman-transmission = {
    requires = [
      "podman-network-media.service"
      "homelab-task-managed-state-restore.service"
    ];
    after = [
      "podman-network-media.service"
      "homelab-task-managed-state-restore.service"
    ];
  };
}
