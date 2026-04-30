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
    image = "lscr.io/linuxserver/prowlarr:2.3.5@sha256:dfec09ff1cf64720ea02b11a0d1f8d16b25a31c6319c745093e3fd7d61f898cc";

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
    image = "lscr.io/linuxserver/bazarr:1.5.6@sha256:334d4284c869e9c76fc402e981be497176c79f7f89eae0d2df95bf9ad5184cd4";

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
    image = "lscr.io/linuxserver/lidarr:3.1.0@sha256:c47f24220fd018c4d114813d9e8d9682fdb6eb47fad99f9895dbe3a40203108f";

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
    image = "lscr.io/linuxserver/radarr:6.1.1@sha256:139e2bff7cc3adda719137c372f6cdee996aea7100f732050cb413690f97ac6e";

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
    image = "lscr.io/linuxserver/sonarr:4.0.17@sha256:f0c4491ac40a97742201b07cc206b120703fcd398fd40536fdc47820d7a5c298";

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
    image = "lscr.io/linuxserver/transmission:4.1.1@sha256:c677a6211a95b94bfc036ec1fe97b3222204eebe95cacbca0db930192ecf015a";

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