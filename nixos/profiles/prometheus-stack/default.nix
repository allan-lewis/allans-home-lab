{ remoteBackupRoot, config, lib, ... }:

let
  alertmanagerEnabled = config.services.homelab.alertmanager.enable;
  grafanaEnabled = config.services.homelab.grafana.enable;
in
{
  imports = [
    ../../modules/alertmanager
    ../../modules/grafana
    ../../modules/prometheus
  ];

  options.homelab.prometheus.friendlyRelabelConfigs = lib.mkOption {
    type = lib.types.listOf lib.types.attrs;
    default = [
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
    description = "Shared relabel_configs for scrape jobs that set __meta_friendly_instance.";
  };

  config = {
    #: declare managed directories for alertmanager and grafana, only when enabled
    homelab.managedDirectories.entries = lib.mkMerge [
      (lib.mkIf alertmanagerEnabled {
        alertmanager = {
          local = "/var/lib/alertmanager";
          remote = "${remoteBackupRoot}/alertmanager";
          restore = true;
          backup = true;
          owner = "nobody";
          group = "nogroup";
          mode = "0750";
        };
      })
      (lib.mkIf grafanaEnabled {
        grafana = {
          local = "/var/lib/grafana";
          remote = "${remoteBackupRoot}/grafana";
          restore = true;
          backup = true;
          owner = "grafana";
          group = "grafana";
          mode = "0750";
        };
      })
    ];

    #: declare sops secrets for alertmanager and grafana, only when enabled
    sops.secrets = lib.mkMerge [
      (lib.mkIf alertmanagerEnabled {
        alertmanager_telegram_env = {
          sopsFile = ./alertmanager-telegram.env;
          format = "dotenv";
          key = "";
        };
      })
      (lib.mkIf grafanaEnabled {
        grafana_secret_key = {
          sopsFile = ./grafana.yaml;
          key = "grafana/secret_key";
          owner = "grafana";
          group = "grafana";
          mode = "0400";
        };
      })
    ];

    #: configure alertmanager
    services.homelab.alertmanager.enable = true;
    services.homelab.alertmanager.environmentFile =
      lib.mkIf alertmanagerEnabled config.sops.secrets.alertmanager_telegram_env.path;

    #: configure grafana
    services.homelab.grafana.enable = true;
    services.homelab.grafana.port = 3071;
    services.homelab.grafana.domain = "grafana.allanshomelab.com";
    services.homelab.grafana.secretKeyFile =
      lib.mkIf grafanaEnabled config.sops.secrets.grafana_secret_key.path;

    #: configure prometheus
    services.homelab.prometheus.enable = true;
    services.homelab.prometheus.ruleFiles = [
      ./rules.yaml
      ./slo-rules.yaml
    ];
  };
}
