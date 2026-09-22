{ hostDns, hostIp4Address, hostIp4Gateway, hostInterface, hostName, nixosVersion, ... }:

{
  imports = [
    ../../profiles/traefik
  ];

  homelab.traefik = {
    authentikIpAddress = "192.168.10.102";

    services = [
      {
        name = "alertmanager";
        host = "alertmanager.nixos.allanshomelab.com";
        url = "http://castor.ip.allanshomelab.com:3070";
        authentik = false;
      }
      {
        name = "allans-home-lab";
        host = "allanshomelab.com";
        url = "http://castor.ip.allanshomelab.com:8976";
        authentik = false;
      }
      {
        name = "authentik";
        host = "authn.allanshomelab.com";
        url = "http://castor.ip.allanshomelab.com:9180";
        authentik = false;
      }
      {
        name = "bazarr";
        host = "bazarr.media.allanshomelab.com";
        url = "http://regulus.ip.allanshomelab.com:6767";
        authentik = true;
      }
      {
        name = "frigate";
        host = "nvr.allanshomelab.com";
        url = "http://pollux.ip.allanshomelab.com:8971";
        authentik = false;
      }
      {
        name = "gatus";
        host = "gatus.nixos.allanshomelab.com";
        url = "http://castor.ip.allanshomelab.com:8080";
        authentik = false;
      }
      {
        name = "rigel";
        host = "rigel.hosts.allanshomelab.com";
        url = "http://rigel.ip.allanshomelab.com";
        authentik = false;
      }
      {
        name = "polaris";
        host = "polaris.hosts.allanshomelab.com";
        url = "http://polaris.ip.allanshomelab.com";
        authentik = false;
      }
      {
        name = "grafana";
        host = "grafana.allanshomelab.com";
        url = "http://castor.ip.allanshomelab.com:3071";
        authentik = false;
      }
      {
        name = "homepage";
        host = "homepage.nixos.allanshomelab.com";
        url = "http://castor.ip.allanshomelab.com:3007";
        authentik = false;
      }
      {
        name = "immich";
        host = "photos.allanandvaia.com";
        url = "http://pollux.ip.allanshomelab.com:2283";
        authentik = false;
      }
      {
        name = "it-tools";
        host = "tools.nixos.allanshomelab.com";
        url = "http://pollux.ip.allanshomelab.com:8386";
        authentik = false;
      }
      {
        name = "jellyfin";
        host = "jellyfin.media.allanshomelab.com";
        url = "http://pollux.ip.allanshomelab.com:8096";
        authentik = false;
      }
      {
        name = "lidarr";
        host = "lidarr.media.allanshomelab.com";
        url = "http://regulus.ip.allanshomelab.com:8686";
        authentik = true;
      }
      {
        name = "nginx";
        host = "nginx.nixos.allanshomelab.com";
        url = "http://pollux.ip.allanshomelab.com";
        authentik = false;
      }
      {
        name = "no-geeks-brewing";
        host = "nogeeksbrewing.com";
        url = "http://pollux.ip.allanshomelab.com";
        authentik = true;
      }
      {
        name = "pennywise";
        host = "pennywise.hosts.allanshomelab.com";
        url = "https://pennywise.ip.allanshomelab.com";
        authentik = false;
      }
      {
        name = "plex";
        host = "plex.media.allanshomelab.com";
        url = "http://pollux.ip.allanshomelab.com:32400";
        authentik = false;
      }
      {
        name = "prometheus";
        host = "prometheus.nixos.allanshomelab.com";
        url = "http://castor.ip.allanshomelab.com:3072";
        authentik = false;
      }
      {
        name = "prowlarr";
        host = "prowlarr.media.allanshomelab.com";
        url = "http://regulus.ip.allanshomelab.com:9696";
        authentik = true;
      }
      {
        name = "radarr";
        host = "radarr.media.allanshomelab.com";
        url = "http://regulus.ip.allanshomelab.com:7878";
        authentik = true;
      }
      {
        name = "sirius";
        host = "sirius.hosts.allanshomelab.com";
        url = "https://sirius.ip.allanshomelab.com:8006";
        authentik = false;
      }
      {
        name = "sirius-kvm";
        host = "sirius.kvm.allanshomelab.com";
        url = "http://sirius-kvm.hosts.allanshomelab.com";
        authentik = false;
      }
      {
        name = "sonarr";
        host = "sonarr.media.allanshomelab.com";
        url = "http://regulus.ip.allanshomelab.com:8989";
        authentik = true;
      }
      {
        name = "tautulli";
        host = "tautulli.media.allanshomelab.com";
        url = "http://pollux.ip.allanshomelab.com:8181";
        authentik = false;
      }
      {
        name = "traefik";
        host = "traefik.nixos.allanshomelab.com";
        url = "http://castor.ip.allanshomelab.com:8088";
        authentik = false;
      }
      {
        name = "transmission";
        host = "transmission.media.allanshomelab.com";
        url = "http://regulus.ip.allanshomelab.com:9091";
        authentik = false;
      }
      {
        name = "trilium";
        host = "notes.allanshomelab.com";
        url = "http://pollux.ip.allanshomelab.com:8376";
        authentik = false;
      }
      {
        name = "vault0";
        host = "129monroe.com";
        url = "http://castor.ip.allanshomelab.com:35550";
        authentik = false;
        excludeAdmin = true;
      }
      {
        name = "vault1";
        host = "vault.129monroe.com";
        url = "http://castor.ip.allanshomelab.com:35550";
        authentik = false;
        excludeAdmin = true;
      }
      {
        name = "vault2";
        host = "vault.allanshomelab.com";
        url = "http://castor.ip.allanshomelab.com:35550";
        authentik = false;
        excludeAdmin = true;
      }
      {
        name = "whoami";
        host = "whoami.nixos.allanshomelab.com";
        url = "http://localhost:8180";
        authentik = false;
      }
      {
        name = "home-assistant-0";
        host = "home.allanandvaia.com";
        url = "http://100.67.41.102:8123";
        authentik = false;
      }
      {
        name = "home-assistant-1";
        host = "allanandvaia.com";
        url = "http://100.67.41.102:8123";
        authentik = false;
      }
    ];
  };

}
