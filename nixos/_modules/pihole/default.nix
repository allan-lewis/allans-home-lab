{ config, lib, ... }:

let
  inherit (lib) mkOption types;
  cfg = config.homelab.pihole;
in
{
  options.homelab.pihole = {
    upstreams = mkOption {
      type = types.listOf types.str;
      default = [
        "1.1.1.1"
        "1.0.0.1"
        "9.9.9.9"
        "149.112.112.112"
      ];
      description = "Upstream DNS servers for Pi-hole.";
    };

    hosts = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Static host records for Pi-hole.";
    };

    cnameRecords = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "CNAME records for Pi-hole.";
    };
  };

  config = {
    services.pihole-ftl = {
      enable = true;

      lists = [
        {
          url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
          type = "block";
          enabled = true;
          description = "Steven Black's HOSTS";
        }
      ];

      openFirewallDNS = true;
      openFirewallWebserver = true;

      settings = {
        dns = {
          upstreams = cfg.upstreams;

          reply.host.force4 = true;

          hosts = cfg.hosts;

          cnameRecords = cfg.cnameRecords;
        };

        webserver = {
          serve_all = true;

          interface = {
            theme = "lcars";
          };

          api = {
            pwhash = "$BALLOON-SHA256$v=1$s=1024,t=32$s8evdyU7n2Rgog+kFqN5tg==$UZbsirVSN+DN+czZtWBzesTonAMjvRZbK8XlGOIQlFI=";
          };
        };

        misc = {
          privacylevel = 0;
          readOnly = true;
        };
      };
    };

    services.pihole-web = {
      enable = true;
      ports = [ 80 ];
    };

    services.resolved.enable = false;

    systemd.tmpfiles.rules = [
      "f /etc/pihole/versions 0644 pihole pihole - -"
    ];

    # Uncomment if you want the host itself to use Pi-hole
    # networking.nameservers = [ "127.0.0.1" ];
  };
}