{ config, ... }:

{
  imports = [
    ../../modules/traefik
  ];

  sops.secrets.cloudflare_api_key = {
    sopsFile = ./traefik.yaml;
    key = "CLOUDFLARE_API_KEY";
  };

  homelab.traefik.email = "allan.e.lewis@gmail.com";

  homelab.traefik.cloudflareApiKey = secrets: secrets.cloudflare_api_key;

  homelab.traefik.authentikIpAddress = "192.168.86.204";

  homelab.traefik.services = [
    {
      name = "129-monroe";
      host = "129monroe.com";
      url = "http://192.168.86.228:35550";
      authentik = false;
      excludeAdmin = true;
    }
    {
      name = "129-vault";
      host = "vault.129monroe.com";
      url = "http://192.168.86.228:35550";
      authentik = false;
      excludeAdmin = true;
    }
    {
      name = "alertmanager";
      host = "alertmanager.nixos.allanshomelab.com";
      url = "http://192.168.86.204:3070";
      authentik = false;
    }
    {
      name = "allan-and-vaia";
      host = "allanandvaia.com";
      url = "http://192.168.86.229:8123";
      authentik = false;
    }
    {
      name = "allans-home-lab";
      host = "allanshomelab.com";
      url = "http://192.168.86.219:3007";
      authentik = true;
    }
    {
      name = "authentik";
      host = "authn.allanshomelab.com";
      url = "http://192.168.86.204:9180";
      authentik = false;
    }
    {
      name = "bazarr";
      host = "bazarr.media.allanshomelab.com";
      url = "http://192.168.86.224:6767";
      authentik = true;
    }
    {
      name = "derry";
      host = "derry.hosts.allanshomelab.com";
      url = "http://192.168.86.210:8000";
      authentik = false;
    }
    {
      name = "gilead";
      host = "gilead.hosts.allanshomelab.com";
      url = "http://100.95.108.6:80";
      authentik = false;
    }
    {
      name = "gatus";
      host = "gatus.nixos.allanshomelab.com";
      url = "http://192.168.86.204:8080";
      authentik = false;
    }
    {
      name = "grafana";
      host = "grafana.allanshomelab.com";
      url = "http://192.168.86.204:3071";
      authentik = false;
    }
    {
      name = "home-assistant";
      host = "home.allanandvaia.com";
      url = "http://192.168.86.229:8123";
      authentik = false;
    }
    {
      name = "homepage";
      host = "homepage.nixos.allanshomelab.com";
      url = "http://192.168.86.228:3007";
      authentik = false;
    }
    {
      name = "immich";
      host = "photos.allanandvaia.com";
      url = "http://192.168.86.227:2283";
      authentik = false;
    }
    {
      name = "it-tools";
      host = "tools.nixos.allanshomelab.com";
      url = "http://192.168.86.228:8386";
      authentik = false;
    }
    {
      name = "jellyfin";
      host = "jellyfin.media.allanshomelab.com";
      url = "http://192.168.86.227:8096";
      authentik = false;
    }
    {
      name = "kvm-maturin";
      host = "maturin.kvm.allanshomelab.com";
      url = "http://192.168.86.248";
      authentik = false;
    }
    {
      name = "lidarr";
      host = "lidarr.media.allanshomelab.com";
      url = "http://192.168.86.224:8686";
      authentik = true;
    }
    {
      name = "maturin";
      host = "maturin.hosts.allanshomelab.com";
      url = "https://192.168.86.200:8006";
      authentik = false;
    }
    {
      name = "nginx";
      host = "nginx.nixos.allanshomelab.com";
      url = "http://192.168.86.228";
      authentik = false;
    }
    {
      name = "no-geeks-brewing";
      host = "nogeeksbrewing.com";
      url = "http://192.168.86.228:8083";
      authentik = false;
    }
    {
      name = "pennywise";
      host = "pennywise.hosts.allanshomelab.com";
      url = "https://192.168.86.220";
      authentik = false;
    }
    {
      name = "pihole";
      host = "dns.nixos.allanshomelab.com";
      url = "http://192.168.86.218";
      authentik = false;
    }
    {
      name = "plex";
      host = "plex.media.allanshomelab.com";
      url = "http://192.168.86.227:32400";
      authentik = false;
    }
    {
      name = "prometheus";
      host = "prometheus.nixos.allanshomelab.com";
      url = "http://192.168.86.204:3072";
      authentik = false;
    }
    {
      name = "prowlarr";
      host = "prowlarr.media.allanshomelab.com";
      url = "http://192.168.86.224:9696";
      authentik = true;
    }
    {
      name = "radarr";
      host = "radarr.media.allanshomelab.com";
      url = "http://192.168.86.224:7878";
      authentik = true;
    }
    {
      name = "sonarr";
      host = "sonarr.media.allanshomelab.com";
      url = "http://192.168.86.224:8989";
      authentik = true;
    }
    {
      name = "tautulli";
      host = "tautulli.media.allanshomelab.com";
      url = "http://192.168.86.227:8181";
      authentik = false;
    }
    {
      name = "traefik";
      host = "traefik.nixos.allanshomelab.com";
      url = "http://127.0.0.1:8088";
      authentik = false;
    }
    {
      name = "transmission";
      host = "transmission.media.allanshomelab.com";
      url = "http://192.168.86.224:9091";
      authentik = false;
    }
    {
      name = "trilium";
      host = "notes.allanshomelab.com";
      url = "http://192.168.86.228:8376";
      authentik = false;
    }
    {
      name = "vaultwarden";
      host = "vault.allanshomelab.com";
      url = "http://192.168.86.228:35550";
      authentik = false;
      excludeAdmin = true;
    }
    {
      name = "whoami";
      host = "whoami.nixos.allanshomelab.com";
      url = "http://127.0.0.1:8180";
      authentik = false;
    }
  ];
}