{ config, lib, ... }:

let
  cfg = config.services.homelab.alertmanager;
  telegramTemplatePath = "/etc/alertmanager/config/telegram.tmpl";
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
      example = lib.literalExpression ''config.sops.secrets.alertmanager_telegram_env.path'';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."alertmanager/config/telegram.tmpl".source =
      ../../assets/alertmanager/telegram.tmpl;

    services.prometheus.alertmanager = {
      enable = true;

      port = cfg.port;
      listenAddress = cfg.listenAddress;
      openFirewall = cfg.openFirewall;
      logLevel = cfg.logLevel;
      extraFlags = cfg.extraFlags;
      environmentFile = cfg.environmentFile;
      webExternalUrl = cfg.webExternalUrl;

      checkConfig = false;

      configText = ''
        global:
          resolve_timeout: 5m
          http_config:
            follow_redirects: true
            enable_http2: true
          telegram_api_url: https://api.telegram.org

        route:
          receiver: "null"
          group_by: ["alertname"]
          group_wait: 30s
          group_interval: 5m
          repeat_interval: 24h

          routes:
            - receiver: "null"
              matchers:
                - alertname="Watchdog"
              continue: false

            - receiver: "telegram"
              matchers:
                - severity="critical"
              continue: false

        receivers:
          - name: "null"

          - name: "telegram"
            telegram_configs:
              - send_resolved: true
                api_url: https://api.telegram.org
                bot_token: "$TELEGRAM_BOT_TOKEN"
                chat_id: $TELEGRAM_CHAT_ID
                message: '{{ template "telegram.default.message" . }}'
                parse_mode: HTML

        templates:
          - ${telegramTemplatePath}
      '';
    };

    systemd.services.alertmanager = {
      requires = [ "homelab-task-managed-state-restore.service" ];
      after = [ "homelab-task-managed-state-restore.service" ];
    };
  };
}