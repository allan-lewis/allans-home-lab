{ backupRemotePrefix, config, ... }:

let
  hostName = "flagg";
  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  imports = [
    ../../profiles/authentik
    ../../profiles/s3-mirror
    
    ../../profiles/alertmanager
    ../../profiles/bare-metal
    ../../profiles/base
    ../../profiles/cloudflare
    ../../profiles/containers/twingate
    ../../profiles/gatus
    ../../profiles/grafana
    ../../profiles/prometheus
    ../../profiles/tailscale
    ../../profiles/traefik
  ];

  networking.hostName = hostName;

  homelab.bareMetal.interface = "eth1";
  homelab.bareMetal.address = "192.168.86.204";

  homelab.managedDirectories.entries = {
    postgres_backup = {
      local = "/var/lib/postgres-db-dumps";
      remote = "${defaultRemoteNasPerHostBackupVolume}/authentik/db-dumps";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
    s3_mirror = {
      local = "/var/lib/s3-mirror";
      remote = "${defaultRemoteNasPerHostBackupVolume}/s3-mirror";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
    grafana = {
      local = "/var/lib/grafana";
      remote = "${defaultRemoteNasPerHostBackupVolume}/grafana";
      restore = true;
      backup = true;
      owner = "grafana";
      group = "grafana";
      mode = "0750";
    };
    alertmanager = {
      local = "/var/lib/alertmanager";
      remote = "${defaultRemoteNasPerHostBackupVolume}/alertmanager";
      restore = true;
      backup = true;
      owner = "nobody";
      group = "nogroup";
      mode = "0750";
    };
  };

  services.homelab.twingateConnector = {
    enable = true;
    connectorKey = "modestAnteater";
    networkName = "allanshomelab";
    image = "twingate/connector:1.87.0@sha256:b348b79b6193062a40b8b6131beda8b2f42e64753e34a5908d93fc73acaeb503";
  };

  services.homelab.cloudflaredTunnel = {
    enable = true;
  };

  services.homelab.prometheus = {
    enable = true;
  };

  sops.secrets.alertmanager_telegram_env = {
    sopsFile = ../../secrets/alertmanager-telegram.env;
    format = "dotenv";
    key = "";
  };

  services.homelab.alertmanager = {
    enable = true;
    environmentFile = config.sops.secrets.alertmanager_telegram_env.path;
  };

  services.homelab.grafana = {
    enable = true;
    port = 3071;
    domain = "grafana.allanshomelab.com";
  };

  system.stateVersion = "25.11";
}