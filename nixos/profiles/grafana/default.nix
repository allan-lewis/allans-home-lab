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

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/grafana";
    };
  };

  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;

      dataDir = cfg.dataDir;

      settings = {
        server = {
          http_addr = cfg.addr;
          http_port = cfg.port;
          domain = cfg.domain;
        };

        security = {
          admin_user = "admin";
        };
      };
    };

    networking.firewall.allowedTCPPorts =
      lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}