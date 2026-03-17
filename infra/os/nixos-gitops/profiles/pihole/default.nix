{ config, lib, pkgs, ... }:

{
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
        upstreams = [ "1.1.1.1" "1.0.0.1" ];
        reply.host.force4 = true;

        hosts = [
          "192.168.86.204 docker.allanshomelab.com"
        ];

        cnameRecords = [
          "alertmanager.docker.allanshomelab.com,docker.allanshomelab.com"
        ];
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
}