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
    image = "ghcr.io/linuxserver/prowlarr:2.4.0@sha256:3950b5e48cf4ba9dab78fe14038dd7f062e66b7b4ab368b02c94a13f6a3dae9f";

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
    image = "ghcr.io/linuxserver/bazarr:1.5.6@sha256:047222423d6d8556a88581b189175bec57f286f120b52ba29c0390fe6babaa5a";

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
    image = "ghcr.io/linuxserver/radarr:6.2.1@sha256:39da107b5a9371fdaa651bd188049b863716a815385eb3a30d41071b7e1aeb33";

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
    image = "ghcr.io/linuxserver/sonarr:4.0.19@sha256:fbb15bb4fb14d1ffe017f6be0e3fed8f1b300e4687e329767da0b61f36ba1eed";

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
    image = "ghcr.io/linuxserver/transmission:4.1.2@sha256:9b229b05a4027a5548285f66b2ba4cbf12bdef83ddac97f726afa94fbae308c0";

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
