{ config, lib, pkgs, ... }:

let
  agentScript = ./check_mk_agent.linux;

  agent = pkgs.writeShellScript "checkmk-agent" ''
    export PATH=${lib.makeBinPath (with pkgs; [
      bash
      coreutils
      findutils
      gnugrep
      gnused
      gawk
      procps
      util-linux
      iproute2
      systemd
      nettools
      ethtool
    ])}:/run/current-system/sw/bin

    exec ${pkgs.bash}/bin/bash ${agentScript}
  '';
in
{
  systemd.sockets.checkmk-agent = {
    description = "Checkmk Agent Socket";

    wantedBy = [ "sockets.target" ];

    listenStreams = [ "6556" ];

    socketConfig = {
      Accept = true;
      MaxConnectionsPerSource = 3;
    };
  };

  systemd.services."checkmk-agent@" = {
    description = "Checkmk Monitoring Agent";

    serviceConfig = {
      Type = "simple";
      ExecStart = agent;
      StandardInput = "socket";
      StandardOutput = "socket";
      User = "root";
    };
  };

  networking.firewall.allowedTCPPorts = [ 6556 ];
}
