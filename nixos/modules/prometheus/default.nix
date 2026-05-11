{ config, lib, ... }:

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

    scrapeConfigs = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Prometheus scrape_configs.";
    };

    ruleFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = "Prometheus rule files.";
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

      scrapeConfigs = cfg.scrapeConfigs;

      alertmanagers = [
        {
          static_configs = [
            {
              targets = [ "127.0.0.1:3070" ];
            }
          ];
        }
      ];

      ruleFiles = cfg.ruleFiles;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}