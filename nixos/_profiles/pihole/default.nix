{ ... }:

{
  imports = [
    ../../_modules/pihole
  ];

  homelab.pihole.hosts = [
    "192.168.86.204 hosts.allanshomelab.com"
    "192.168.86.204 media.allanshomelab.com"
    "192.168.86.204 nixos.allanshomelab.com"
    "192.168.86.204 kvm.allanshomelab.com"
  ];

  homelab.pihole.cnameRecords = [
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
    "alertmanager.nixos.allanshomelab.com,nixos.allanshomelab.com"
    "dns.nixos.allanshomelab.com,nixos.allanshomelab.com"
    "gatus.nixos.allanshomelab.com,nixos.allanshomelab.com"
    "homepage.nixos.allanshomelab.com,nixos.allanshomelab.com"
    "nginx.nixos.allanshomelab.com,nixos.allanshomelab.com"
    "prometheus.nixos.allanshomelab.com,nixos.allanshomelab.com"
    "tools.nixos.allanshomelab.com,nixos.allanshomelab.com"
    "traefik.nixos.allanshomelab.com,nixos.allanshomelab.com"
    "whoami.nixos.allanshomelab.com,nixos.allanshomelab.com"
  ];
}