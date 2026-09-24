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
  sops.secrets.grafana_secret_key = {
    sopsFile = ./grafana.yaml;
    key = "grafana/secret_key";
    owner = "grafana";
    group = "grafana";
    mode = "0400";
  };

  services.homelab.grafana = {
    enable = true;
    port = 3071;
    domain = "grafana.allanshomelab.com";
    secretKeyFile = config.sops.secrets.grafana_secret_key.path;
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
            targets = [ "rigel.ip.allanshomelab.com:9100" ];
            labels.__meta_friendly_instance = "rigel";
          }
          {
            targets = [ "castor.ip.allanshomelab.com:9100" ];
            labels.__meta_friendly_instance = "castor";
          }
          {
            targets = [ "bellatrix.ip.allanshomelab.com:9100" ];
            labels.__meta_friendly_instance = "bellatrix";
          }
          {
            targets = [ "polaris.ip.allanshomelab.com:9100" ];
            labels.__meta_friendly_instance = "polaris";
          }
          {
            targets = [ "pollux.ip.allanshomelab.com:9100" ];
            labels.__meta_friendly_instance = "pollux";
          }
          {
            targets = [ "capella.ip.allanshomelab.com:9100" ];
            labels.__meta_friendly_instance = "capella";
          }
          {
            targets = [ "regulus.ip.allanshomelab.com:9100" ];
            labels.__meta_friendly_instance = "regulus";
          }
          {
            targets = [ "sirius.ip.allanshomelab.com:9100" ];
            labels.__meta_friendly_instance = "sirius";
          }
          {
            targets = [ "canopus.ip.allanshomelab.com:9100" ];
            labels.__meta_friendly_instance = "canopus";
          }
        ];
        relabel_configs = friendlyRelabelConfigs;
      }

      {
        job_name = "cloudflare";
        static_configs = [
          {
            targets = [ "castor.ip.allanshomelab.com:2000" ];
            labels.__meta_friendly_instance = "castor";
          }
        ];
        relabel_configs = friendlyRelabelConfigs;
      }

      {
        job_name = "todo";
        static_configs = [
          {
            targets = [ "192.168.86.212:9100" ];
            labels.__meta_friendly_instance = "christine";
          }
          {
            targets = [ "192.168.86.211:9100" ];
            labels.__meta_friendly_instance = "gan";
          }
        ];
        relabel_configs = friendlyRelabelConfigs;
      }

      {
        job_name = "gatus";
        static_configs = [
          {
            targets = [ "castor.ip.allanshomelab.com:8080" ];
            labels.__meta_friendly_instance = "castor";
          }
        ];
        relabel_configs = friendlyRelabelConfigs;
      }

      {
        job_name = "homelab-metrics";
        static_configs = [
          {
            targets = [ "bellatrix.ip.allanshomelab.com:9102" ];
            labels.__meta_friendly_instance = "bellatrix";
          }
          {
            targets = [ "castor.ip.allanshomelab.com:9102" ];
            labels.__meta_friendly_instance = "castor";
          }
          {
            targets = [ "pollux.ip.allanshomelab.com:9102" ];
            labels.__meta_friendly_instance = "pollux";
          }
          {
            targets = [ "capella.ip.allanshomelab.com:9102" ];
            labels.__meta_friendly_instance = "capella";
          }
          {
            targets = [ "regulus.ip.allanshomelab.com:9102" ];
            labels.__meta_friendly_instance = "regulus";
          }
        ];
        relabel_configs = friendlyRelabelConfigs;
      }
    ];
  };
}
