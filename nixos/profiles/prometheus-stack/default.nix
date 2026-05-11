{ remoteBackupRoot, config, ... }:

let
  friendlyRelabelConfigs = [
    {
      action = "replace";
      source_labels = [ "__address__" ];
      target_label = "target";
    }
    {
      action = "replace";
      source_labels = [ "__meta_friendly_instance" ];
      target_label = "instance";
    }
  ];
in
{
  imports = [
    ../../modules/alertmanager
    ../../modules/grafana
    ../../modules/prometheus
  ];

  #: declare managed directories for alertmanager and grafana
  homelab.managedDirectories.entries = {
    alertmanager = {
      local = "/var/lib/alertmanager";
      remote = "${remoteBackupRoot}/alertmanager";
      restore = true;
      backup = true;
      owner = "nobody";
      group = "nogroup";
      mode = "0750";
    };
    grafana = {
      local = "/var/lib/grafana";
      remote = "${remoteBackupRoot}/grafana";
      restore = true;
      backup = true;
      owner = "grafana";
      group = "grafana";
      mode = "0750";
    };
  };

  #: configure alertmanager
  sops.secrets.alertmanager_telegram_env = {
    sopsFile = ./alertmanager-telegram.env;
    format = "dotenv";
    key = "";
  };

  services.homelab.alertmanager = {
    enable = true;
    environmentFile = config.sops.secrets.alertmanager_telegram_env.path;
  };

  #: configure grafana
  services.homelab.grafana = {
    enable = true;
    port = 3071;
    domain = "grafana.allanshomelab.com";
  };

  #: configure prometheus
  services.homelab.prometheus = {
    enable = true;

    ruleFiles = [
      ./rules.yaml
    ];

    scrapeConfigs = [
      {
        job_name = "node-exporter";
        static_configs = [
          {
            targets = [ "192.168.86.222:9100" ];
            labels.__meta_friendly_instance = "blaine";
          }
          {
            targets = [ "192.168.86.228:9100" ];
            labels.__meta_friendly_instance = "carrie";
          }
          {
            targets = [ "192.168.86.219:9100" ];
            labels.__meta_friendly_instance = "cujo";
          }
          {
            targets = [ "192.168.86.217:9100" ];
            labels.__meta_friendly_instance = "dandelo";
          }
          {
            targets = [ "192.168.86.210:9100" ];
            labels.__meta_friendly_instance = "derry";
          }
          {
            targets = [ "192.168.86.204:9100" ];
            labels.__meta_friendly_instance = "flagg";
          }
          {
            targets = [ "100.95.108.6:9100" ];
            labels.__meta_friendly_instance = "gilead";
          }
          {
            targets = [ "192.168.86.218:9100" ];
            labels.__meta_friendly_instance = "langolier";
          }
          {
            targets = [ "192.168.86.200:9100" ];
            labels.__meta_friendly_instance = "maturin";
          }
          {
            targets = [ "192.168.86.227:9100" ];
            labels.__meta_friendly_instance = "misery";
          }
          {
            targets = [ "192.168.86.229:9100" ];
            labels.__meta_friendly_instance = "overlook";
          }
          {
            targets = [ "192.168.86.224:9100" ];
            labels.__meta_friendly_instance = "patricia";
          }
          {
            targets = [ "192.168.86.220:9100" ];
            labels.__meta_friendly_instance = "pennywise";
          }
          {
            targets = [ "192.168.86.206:9100" ];
            labels.__meta_friendly_instance = "roland";
          }
        ];
        relabel_configs = friendlyRelabelConfigs;
      }

      {
        job_name = "cloudflare";
        static_configs = [
          {
            targets = [ "192.168.86.204:2000" ];
            labels.__meta_friendly_instance = "flagg";
          }
        ];
        relabel_configs = friendlyRelabelConfigs;
      }

      {
        job_name = "gatus";
        static_configs = [
          {
            targets = [ "192.168.86.204:8080" ];
            labels.__meta_friendly_instance = "flagg";
          }
        ];
        relabel_configs = friendlyRelabelConfigs;
      }

      {
        job_name = "homelab-metrics";
        static_configs = [
          {
            targets = [ "192.168.86.228:9102" ];
            labels.__meta_friendly_instance = "carrie";
          }
          {
            targets = [ "192.168.86.219:9102" ];
            labels.__meta_friendly_instance = "cujo";
          }
          {
            targets = [ "192.168.86.204:9102" ];
            labels.__meta_friendly_instance = "flagg";
          }
          {
            targets = [ "192.168.86.218:9102" ];
            labels.__meta_friendly_instance = "langolier";
          }
          {
            targets = [ "192.168.86.227:9102" ];
            labels.__meta_friendly_instance = "misery";
          }
          {
            targets = [ "192.168.86.224:9102" ];
            labels.__meta_friendly_instance = "patricia";
          }
        ];
        relabel_configs = friendlyRelabelConfigs;
      }
    ];
  };
}