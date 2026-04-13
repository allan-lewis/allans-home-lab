{ config, pkgs, 
  mediaLibraryDir, 
  bazarrConfigDir, 
  lidarrConfigDir, 
  prowlarrConfigDir, 
  transmissionConfigDir, transmissionWatchDir,
  ... 
}:

{
  virtualisation.oci-containers.containers.prowlarr = {
    image = "lscr.io/linuxserver/prowlarr:2.3.5@sha256:7733304106a9c49b9036279293bcac4441ef2356b4aa0018d21e6cd9df0193b8";

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
    image = "lscr.io/linuxserver/bazarr:1.5.6@sha256:2eeeaaccff97783fde4c34c0fe9690f9acd42964a2542b577381eb807793d492";

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

  virtualisation.oci-containers.containers.transmission = {
    image = "lscr.io/linuxserver/transmission:4.1.1@sha256:e8e4c55ea4b1ed0d7cea4d40160c94688d6cbbe3dba6d159c97c4f6641413c71";

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