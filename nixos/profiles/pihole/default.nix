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
        upstreams = [
          "1.1.1.1"
          "1.0.0.1"
          "9.9.9.9"
          "149.112.112.112"
        ];

        reply.host.force4 = true;

        hosts = [
          "192.168.86.204 docker.allanshomelab.com"
          "192.168.86.204 hosts.allanshomelab.com"
          "192.168.86.204 media.allanshomelab.com"
          "192.168.86.204 nixos.allanshomelab.com"
          "192.168.86.204 kvm.allanshomelab.com"
        ];

        cnameRecords = [
          ## DOCKER
          "alertmanager.docker.allanshomelab.com,docker.allanshomelab.com"
          "homepage.docker.allanshomelab.com,docker.allanshomelab.com"
          "prometheus.docker.allanshomelab.com,docker.allanshomelab.com"
          ## HOSTS
          "derry.hosts.allanshomelab.com,hosts.allanshomelab.com"
          "gilead.hosts.allanshomelab.com,hosts.allanshomelab.com"
          "maturin.hosts.allanshomelab.com,hosts.allanshomelab.com"
          "pennywise.hosts.allanshomelab.com,hosts.allanshomelab.com"
          ## KVM
          "maturin.kvm.allanshomelab.com,kvm.allanshomelab.com"
          ## MEDIA
          "bazarr.media.allanshomelab.com,media.allanshomelab.com"
          "jellyfin.media.allanshomelab.com,media.allanshomelab.com"
          "lidarr.media.allanshomelab.com,media.allanshomelab.com"
          "plex.media.allanshomelab.com,media.allanshomelab.com"
          "prowlarr.media.allanshomelab.com,media.allanshomelab.com"
          "radarr.media.allanshomelab.com,media.allanshomelab.com"
          "sonarr.media.allanshomelab.com,media.allanshomelab.com"
          "tautulli.media.allanshomelab.com,media.allanshomelab.com"
          "transmission.media.allanshomelab.com,media.allanshomelab.com"
          ## NIXOS
          "dns.nixos.allanshomelab.com,nixos.allanshomelab.com"
          "gatus.nixos.allanshomelab.com,nixos.allanshomelab.com"
          "nginx.nixos.allanshomelab.com,nixos.allanshomelab.com"
          "tools.nixos.allanshomelab.com,nixos.allanshomelab.com"
          "traefik.nixos.allanshomelab.com,nixos.allanshomelab.com"
          "whoami.nixos.allanshomelab.com,nixos.allanshomelab.com"
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