{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.homelab.openvpnClient;
  serviceName = "openvpn-${cfg.name}";
  renderedConfig = pkgs.writeText "openvpn-${cfg.name}.conf" ''
    ${builtins.readFile cfg.configFile}
  '';
in
{
  options.services.homelab.openvpnClient = {
    enable = mkEnableOption "OpenVPN client";

    name = mkOption {
      type = types.str;
      default = "client";
    };

    configFile = mkOption {
      type = types.path;
      description = "OpenVPN client config file";
    };

    restartDaily = mkOption {
      type = types.bool;
      default = true;
    };

    restartTime = mkOption {
      type = types.str;
      default = "00:00";
    };
  };

  config = mkIf cfg.enable {
    services.openvpn.servers.${cfg.name} = {
      config = "config ${renderedConfig}";
      autoStart = true;
    };

    systemd.timers."${serviceName}-restart" = mkIf cfg.restartDaily {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* ${cfg.restartTime}:00";
        Persistent = true;
      };
    };

    systemd.services."${serviceName}-restart" = mkIf cfg.restartDaily {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl restart ${serviceName}.service";
      };
    };
  };
}