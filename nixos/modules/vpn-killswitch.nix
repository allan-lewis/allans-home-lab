{ config, lib, ... }:

with lib;

let
  cfg = config.services.homelab.vpnKillSwitch;

  lanSubnets = concatStringsSep ", " cfg.lanSubnets;
  vpnEndpointIps = concatStringsSep ", " cfg.vpnEndpointIps;

  inputRules = concatMapStringsSep "\n" (subnet: ''
    ip saddr ${subnet} iifname "${cfg.wanInterface}" accept
  '') cfg.lanSubnets;

  forwardRules = concatMapStringsSep "\n" (subnet: ''
    ip saddr ${subnet} iifname "${cfg.wanInterface}" oifname "${cfg.vpnInterface}" accept
    ip daddr ${subnet} iifname "${cfg.vpnInterface}" oifname "${cfg.wanInterface}" ct state established,related accept
  '') cfg.lanSubnets;

  postroutingRules = concatMapStringsSep "\n" (subnet: ''
    oifname "${cfg.vpnInterface}" ip saddr ${subnet} masquerade
  '') cfg.lanSubnets;
in
{
  options.services.homelab.vpnKillSwitch = {
    enable = mkEnableOption "VPN kill switch for routed OpenVPN gateway traffic";

    wanInterface = mkOption {
      type = types.str;
      description = "LAN/WAN-facing physical interface on the gateway host";
      example = "eth0";
    };

    vpnInterface = mkOption {
      type = types.str;
      default = "tun0";
      description = "VPN tunnel interface";
    };

    lanSubnets = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Trusted LAN IPv4 CIDRs allowed to reach and route through the gateway";
      example = [ "192.168.86.0/24" ];
    };

    vpnEndpointIps = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Explicit VPN server IPv4 addresses allowed out on the physical interface";
      example = [ "45.84.216.183" "45.84.216.83" ];
    };

    vpnPort = mkOption {
      type = types.port;
      description = "VPN server port";
      example = 1195;
    };

    vpnProtocol = mkOption {
      type = types.enum [ "udp" "tcp" ];
      default = "udp";
      description = "VPN transport protocol";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.lanSubnets != [];
        message = "services.homelab.vpnKillSwitch.lanSubnets must not be empty";
      }
      {
        assertion = cfg.vpnEndpointIps != [];
        message = "services.homelab.vpnKillSwitch.vpnEndpointIps must not be empty";
      }
    ];

    networking.nftables.enable = true;

    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    networking.nftables.ruleset = mkAfter ''
      table inet homelab_vpn_killswitch {
        chain input {
          type filter hook input priority 0; policy drop;

          iifname "lo" accept
          ct state established,related accept

          # Keep LAN management access to the gateway.
          ${inputRules}

          # Optional but sensible.
          ip protocol icmp accept
          ip6 nexthdr icmpv6 accept
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ct state established,related accept

          # Allow LAN clients to forward only into the VPN tunnel.
          ${forwardRules}
        }

        chain output {
          type filter hook output priority 0; policy drop;

          oifname "lo" accept
          ct state established,related accept

          # Allow the host to talk to the local LAN.
          ip daddr { ${lanSubnets} } oifname "${cfg.wanInterface}" accept

          # Allow all traffic once it is going through the VPN tunnel.
          oifname "${cfg.vpnInterface}" accept

          # Only allow the physical interface to reach the VPN provider endpoints.
          oifname "${cfg.wanInterface}" ip daddr { ${vpnEndpointIps} } ${cfg.vpnProtocol} dport ${toString cfg.vpnPort} accept
        }
      }

      table ip homelab_vpn_nat {
        chain postrouting {
          type nat hook postrouting priority 100; policy accept;

          # NAT LAN client traffic out the VPN tunnel.
          ${postroutingRules}
        }
      }
    '';
  };
}