{ backupRoot, config, ... }:

{
  imports = [
    ../../modules/alertmanager
    ../../modules/grafana
    ../../modules/prometheus
  ];

  homelab.managedDirectories.entries = {
    alertmanager = {
      local = "/var/lib/alertmanager";
      remote = "${backupRoot}/alertmanager";
      restore = true;
      backup = true;
      owner = "nobody";
      group = "nogroup";
      mode = "0750";
    };
    grafana = {
      local = "/var/lib/grafana";
      remote = "${backupRoot}/grafana";
      restore = true;
      backup = true;
      owner = "grafana";
      group = "grafana";
      mode = "0750";
    };
  };

  sops.secrets.alertmanager_telegram_env = {
    sopsFile = ./secrets/alertmanager-telegram.env;
    format = "dotenv";
    key = "";
  };

  services.homelab.prometheus = {
    enable = true;
  }; 

  services.homelab.grafana = {
    enable = true;
    port = 3071;
    domain = "grafana.allanshomelab.com";
  };

  services.homelab.alertmanager = {
    enable = true;
    environmentFile = config.sops.secrets.alertmanager_telegram_env.path;
  };
}