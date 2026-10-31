{ config, pkgs, 
  mediaLibraryDir, 
  bazarrConfigDir, 
  lidarrConfigDir, 
  prowlarrConfigDir, 
  radarrConfigDir,
  seerConfigDir,
  sonarrConfigDir,
  transmissionConfigDir, transmissionWatchDir,
  ... 
}:

{
  virtualisation.oci-containers.containers.seer = {
    image = "ghcr.io/seerr-team/seerr:v3.5.1@sha256:2636191726a315dbd75228537f7be74b2fa7498998bb22e37b5b5c8756018fba";

    autoStart = true;

    ports = [ "5055:5055" ];

    volumes = [
      "${seerConfigDir}:/app/config"
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
    image = "ghcr.io/linuxserver/prowlarr:2.7.0@sha256:04be30163fbaf48d6aeee7b5893c9f6614ffbad6d853971df0d6dcdf01c7f104";

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
    image = "ghcr.io/linuxserver/bazarr:1.6.2@sha256:9a625883f054e722795affe5e3ca71057e6ed817ecdf99f4a99624346fcc509c";

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
    image = "ghcr.io/linuxserver/lidarr:3.1.6@sha256:9fddcf5c613361edfce390d4e6b7c364282e71e90a40ce7793077fed788f6e63";

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
    image = "ghcr.io/linuxserver/radarr:6.4.4@sha256:084b3b2ab1d0ef930660727259546a241f2bdf67c9ed085d54bf1486a6887c9b";

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
    image = "ghcr.io/linuxserver/sonarr:4.0.20@sha256:386c962ee6e260e3a5656b25df2ed056bcc9b6410e197d075f9547fd14c23bca";

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
    image = "ghcr.io/linuxserver/transmission:4.1.4@sha256:5b3c27a96c8a37c878a525ebf377a32032c3a3acfe845ecaa7c3eb10b09c2caa";

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
               "posman-seer.service"
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

  systemd.services.podman-seer = {
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
