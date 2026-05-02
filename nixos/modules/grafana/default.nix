{ config, lib, ... }:

let
  cfg = config.services.homelab.grafana;
in
{
  options.services.homelab.grafana = {
    enable = lib.mkEnableOption "homelab Grafana";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };

    addr = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
    };

    protocol = lib.mkOption {
      type = lib.types.enum [ "http" "https" ];
      default = "http";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/grafana";
    };

    prometheusUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:3072";
    };

    prometheusDatasourceName = lib.mkOption {
      type = lib.types.str;
      default = "Prometheus";
    };
  };

  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;

      dataDir = cfg.dataDir;

      settings = {
      server = {
        protocol = cfg.protocol;
        http_addr = cfg.addr;
        http_port = cfg.port;
        domain = cfg.domain;
        root_url = "https://${cfg.domain}";
      };

        security = {
          admin_user = "admin";
        };
      };

      provision = {
        enable = true;

        datasources.settings = {
          apiVersion = 1;

          datasources = [
            {
              name = cfg.prometheusDatasourceName;
              type = "prometheus";
              access = "proxy";
              url = cfg.prometheusUrl;
              isDefault = true;
            }
          ];
        };
      };
    };

    systemd.services.grafana = {
      requires = [ "homelab-task-managed-state-restore.service" ];
      after = [ "homelab-task-managed-state-restore.service" ];
    };

    networking.firewall.allowedTCPPorts =
      lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}