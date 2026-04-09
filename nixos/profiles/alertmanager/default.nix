{ config, lib, pkgs, ... }:

let
  cfg = config.services.homelab.alertmanager;
in
{
  options.services.homelab.alertmanager = {
    enable = lib.mkEnableOption "homelab Alertmanager";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3070;
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "debug" "info" "warn" "error" "fatal" ];
      default = "info";
    };

    webExternalUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.alertmanager = {
      enable = true;

      port = cfg.port;
      listenAddress = cfg.listenAddress;
      openFirewall = cfg.openFirewall;
      logLevel = cfg.logLevel;
      extraFlags = cfg.extraFlags;
      environmentFile = cfg.environmentFile;
      webExternalUrl = cfg.webExternalUrl;

      configuration = {
        global = { };

        route = {
          receiver = "default";
        };

        receivers = [
          {
            name = "default";
          }
        ];
      };
    };

    systemd.services.prometheus-alertmanager = {
      requires = [ "homelab-task-managed-state-restore.service" ];
      after = [ "homelab-task-managed-state-restore.service" ];
    };
  };
}