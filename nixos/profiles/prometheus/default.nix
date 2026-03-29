{ config, lib, pkgs, ... }:

let
  cfg = config.services.homelab.prometheus;
in
{
  options.services.homelab.prometheus = {
    enable = lib.mkEnableOption "homelab Prometheus";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3072;
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    retentionTime = lib.mkOption {
      type = lib.types.str;
      default = "14d";
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      port = cfg.port;
      retentionTime = cfg.retentionTime;

      globalConfig = {
        scrape_interval = "15s";
        evaluation_interval = "15s";
      };

      scrapeConfigs = [
        {
          job_name = "node-exporter";
          static_configs = [
            {
              targets = [ "192.168.86.223:9100" ];
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
          relabel_configs = [
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
        }

        {
          job_name = "cloudflare";
          static_configs = [
            {
              targets = [ "192.168.86.204:2000" ];
              labels.__meta_friendly_instance = "flagg";
            }
          ];
          relabel_configs = [
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
        }

        {
          job_name = "gatus";
          static_configs = [
            {
              targets = [ "192.168.86.204:8080" ];
              labels.__meta_friendly_instance = "flagg";
            }
          ];
          relabel_configs = [
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
          relabel_configs = [
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
        }
      ];

      # Starting point from your current prometheus.yml:
      # alerting = {
      #   alertmanagers = [
      #     {
      #       static_configs = [
      #         { targets = [ "alertmanager:9093" ]; }
      #       ];
      #     }
      #   ];
      # };
      #
      # ruleFiles = [
      #   "/etc/prometheus/rules.yml"
      # ];
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}