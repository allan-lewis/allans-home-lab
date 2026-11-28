{ config, pkgs, 
  mediaLibraryDir, 
  bazarrConfigDir, 
  lidarrConfigDir, 
  prowlarrConfigDir, 
  radarrConfigDir,
  seerrConfigDir,
  sonarrConfigDir,
  transmissionConfigDir, transmissionWatchDir,
  ... 
}:

{
  virtualisation.oci-containers.containers.seerr = {
    image = "ghcr.io/seerr-team/seerr:v3.5.2";

    autoStart = true;

    ports = [ "5055:5055" ];

    volumes = [
      "${seerrConfigDir}:/app/config"
    ];

    environment = {
      TZ = config.time.timeZone;
    };

    networks = [ "media" ];

    extraOptions = [
      "--init"
      "--security-opt=no-new-privileges"
      "--cap-drop=ALL"
      "--health-cmd=wget --no-verbose --tries=1 --spider http://localhost:5055/api/v1/settings/public || exit 1"
      "--health-start-period=20s"
      "--health-timeout=3s"
      "--health-interval=15s"
      "--health-retries=3"
      "--health-on-failure=kill"
    ];
  };

  virtualisation.oci-containers.containers.prowlarr = {
    image = "ghcr.io/linuxserver/prowlarr:3.1.0@sha256:39f07a8b9d1368ca4bb15c5bcc38e2eca0a7690784d2bbe6595bf4ecb5538b03";

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
    image = "ghcr.io/linuxserver/bazarr:1.6.2@sha256:6a49c3a85092037e8e4c2f4fa290bd2ce81bfe61004f728715906dfabafd32a1";

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
    image = "ghcr.io/linuxserver/lidarr:3.1.6@sha256:019985f4289fcd04d830febac4120c4849be7787e8539ec5f1a38d101dbe5434";

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
    image = "ghcr.io/linuxserver/radarr:7.0.3@sha256:ff1b1f21a200e19f52017bd1544031143715b1ab262b823a9dcb916a71da0956";

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
    image = "ghcr.io/linuxserver/sonarr:4.0.20@sha256:93a83fe8193db5f96deedbc0ef30ce4e233689ec6816576d8d284227ccfb3b74";

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
    image = "ghcr.io/linuxserver/transmission:4.1.4@sha256:ebec328b123a430e5b04ff1ff09956d443cac3e37f696c1e7e42ea6f1aad6633";

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
    before = [ 
               "podman-bazarr.service"
               "podman-lidarr.service"
               "podman-prowlarr.service"
               "podman-radarr.service"
               "podman-seerr.service"
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
    unitConfig.RequiresMountsFor = [ mediaLibraryDir ];
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
    unitConfig.RequiresMountsFor = [ mediaLibraryDir ];
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
    unitConfig.RequiresMountsFor = [ mediaLibraryDir ];
  };

  systemd.services.podman-seerr = {
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
    unitConfig.RequiresMountsFor = [ mediaLibraryDir ];
  };
}
