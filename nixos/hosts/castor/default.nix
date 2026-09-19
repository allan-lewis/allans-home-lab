{ hostIp4Address, hostIp4Gateway, hostInterface, hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/bare-metal
    ../../modules/tailscale

    ../../profiles/authentik
    ../../profiles/cloudflare
    ../../profiles/gatus
    ../../profiles/homelab-dashboard
    ../../profiles/homepage
    ../../profiles/prometheus-stack
    ../../profiles/s3-mirror
    ../../profiles/traefik
    ../../profiles/twingate
    ../../profiles/vaultwarden
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostIp4Address;
    gateway = hostIp4Gateway;
  };

  services.homelab.managedState.schedule = "*:30";

  homelab.twingate = {
    enable = true;
    connectorName = "modestAnteater";
  };

  homelab.gatus.endpoints = secrets: [
    {
      name = "Capella (NixOS VPN)";
      group = "Hosts";
      enabled = true;
      url = "icmp://capella.ip.allanshomelab.com";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Bellatrix (NixOS DevOps)";
      group = "Hosts";
      enabled = true;
      url = "icmp://bellatrix.ip.allanshomelab.com";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Castor (NixOS Applications)";
      group = "Hosts";
      enabled = true;
      url = "icmp://castor.ip.allanshomelab.com";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Pollux (NixOS Applications)";
      group = "Hosts";
      enabled = true;
      url = "icmp://pollux.ip.allanshomelab.com";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Regulus (NixOS R Stack)";
      group = "Hosts";
      enabled = true;
      url = "icmp://regulus.ip.allanshomelab.com";
      conditions = [ "[CONNECTED] == true" ];
    }

      {
        name = "Rigel (Remote Backup)";
        group = "Hosts";
        enabled = true;
        url = "icmp://rigel.ip.allanshomelab.com";
        conditions = [ "[CONNECTED] == true" ];
      }
      {
        name = "Pennywise (NAS)";
        group = "Hosts";
        enabled = true;
        url = "icmp://pennywise.ip.allanshomelab.com";
        conditions = [ "[CONNECTED] == true" ];
      }
      {
        name = "Gatus";
        group = "Sites (NixOS)";
        url = "https://gatus.nixos.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Gatus*)"
        ];
      }
      {
        name = "Traefik";
        group = "Sites (NixOS)";
        url = "https://traefik.nixos.allanshomelab.com/dashboard/#/";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Traefik*)"
        ];
      }
      {
        name = "Plex";
        group = "Sites (Media)";
        url = "https://plex.media.allanshomelab.com/web/index.html";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Plex*)"
        ];
      }
      {
        name = "Jellyfin";
        group = "Sites (Media)";
        url = "https://jellyfin.media.allanshomelab.com/web/";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Jellyfin*)"
        ];
      }
      {
        name = "Whoami";
        group = "Sites (NixOS)";
        url = "https://whoami.nixos.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*whoami.nixos.allanshomelab.com*)"
        ];
      }
      # {
      #   name = "Derry";
      #   group = "Sites (Hosts)";
      #   url = "https://derry.hosts.allanshomelab.com";
      #   conditions = [
      #     "[STATUS] == 200"
      #     "[CERTIFICATE_EXPIRATION] > 168h"
      #     "[BODY] == pat(*portal*)"
      #   ];
      # }
      # {
      #   name = "Maturin";
      #   group = "Sites (Hosts)";
      #   url = "https://maturin.hosts.allanshomelab.com";
      #   conditions = [
      #     "[STATUS] == 200"
      #     "[CERTIFICATE_EXPIRATION] > 168h"
      #     "[BODY] == pat(*Proxmox*)"
      #   ];
      # }
      {
        name = "Pennywise";
        group = "Sites (Hosts)";
        url = "https://pennywise.hosts.allanshomelab.com/ui/";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*ix-root*)"
        ];
      }
      {
        name = "Rigel";
        group = "Sites (Hosts)";
        url = "https://rigel.hosts.allanshomelab.com/ui/";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*ix-root*)"
        ];
      }
      {
        name = "Allan's Home Lab";
        group = "Sites (Allan's Home Lab)";
        url = "https://allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Dashboard*)"
        ];
      }
      {
        name = "Frigate";
        group = "Sites (Allan's Home Lab)";
        url = "https://nvr.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Frigate*)"
        ];
      }
      {
        name = "Allan's Home Lab (www)";
        group = "Sites (Allan's Home Lab)";
        url = "https://www.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Dashboard*)"
        ];
      }
      {
        name = "Allan & Vaia";
        group = "Sites (Allan & Vaia)";
        url = "https://allanandvaia.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Home Assistant*)"
        ];
      }
      {
        name = "Allan & Vaia (www)";
        group = "Sites (Allan & Vaia)";
        url = "https://www.allanandvaia.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Home Assistant*)"
        ];
      }
      {
        name = "Home Assistant";
        group = "Sites (Allan & Vaia)";
        url = "https://home.allanandvaia.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Home Assistant*)"
        ];
      }
      {
        name = "Immich";
        group = "Sites (Allan & Vaia)";
        url = "https://photos.allanandvaia.com/api/server/ping";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*pong*)"
        ];
      }
      {
        name = "Trilium";
        group = "Sites (Allan's Home Lab)";
        url = "https://notes.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Trilium*)"
        ];
      }
      {
        name = "Grafana";
        group = "Sites (Allan's Home Lab)";
        url = "https://grafana.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Grafana*)"
        ];
      }
      {
        name = "Vaultwarden (Allan's Home Lab)";
        group = "Sites (Allan's Home Lab)";
        url = "https://vault.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Vaultwarden*)"
        ];
      }
      {
        name = "129 Monroe";
        group = "Sites (129 Monroe)";
        url = "https://129monroe.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Vaultwarden*)"
        ];
      }
      {
        name = "129 Monroe (www)";
        group = "Sites (129 Monroe)";
        url = "https://www.129monroe.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Vaultwarden*)"
        ];
      }
      {
        name = "Vaultwarden (129 Monroe)";
        group = "Sites (129 Monroe)";
        url = "https://vault.129monroe.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Vaultwarden*)"
        ];
      }
      {
        name = "Public Website";
        group = "Sites (No Geeks Brewing)";
        url = "https://nogeeksbrewing.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*authentik*)"
        ];
      }
      {
        name = "Public Website (www)";
        group = "Sites (No Geeks Brewing)";
        url = "https://www.nogeeksbrewing.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*authentik*)"
        ];
      }
      {
        name = "IT Tools";
        group = "Sites (NixOS)";
        url = "https://tools.nixos.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*IT Tools*)"
        ];
      }
      {
        name = "Alertmanager";
        group = "Sites (NixOS)";
        url = "https://alertmanager.nixos.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Alertmanager*)"
        ];
      }
        {
          name = "Prowlarr";
          group = "Sites (Media)";
          url = "https://prowlarr.media.allanshomelab.com/ping";
          conditions = [
            "[STATUS] == 200"
            "[CERTIFICATE_EXPIRATION] > 168h"
            "[BODY] == pat(*authentik*)"
          ];
        }
      {
        name = "Homepage";
        group = "Sites (NixOS)";
        url = "https://homepage.nixos.allanshomelab.com/auth/signin";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Home Lab*)"
        ];
      }
      {
        name = "Prometheus";
        group = "Sites (NixOS)";
        url = "https://prometheus.nixos.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Prometheus*)"
        ];
      }
        {
          name = "Sonarr";
          group = "Sites (Media)";
          url = "https://sonarr.media.allanshomelab.com/ping";
          conditions = [
            "[STATUS] == 200"
            "[CERTIFICATE_EXPIRATION] > 168h"
            "[BODY] == pat(*authentik*)"
          ];
        }
        {
          name = "Radarr";
          group = "Sites (Media)";
          url = "https://radarr.media.allanshomelab.com/ping";
          conditions = [
            "[STATUS] == 200"
            "[CERTIFICATE_EXPIRATION] > 168h"
            "[BODY] == pat(*authentik*)"
          ];
        }
        {
          name = "Lidarr";
          group = "Sites (Media)";
          url = "https://lidarr.media.allanshomelab.com/ping";
          conditions = [
            "[STATUS] == 200"
            "[CERTIFICATE_EXPIRATION] > 168h"
            "[BODY] == pat(*authentik*)"
          ];
        }
        {
          name = "Bazarr";
          group = "Sites (Media)";
          url = "https://bazarr.media.allanshomelab.com";
          conditions = [
            "[STATUS] == 200"
            "[CERTIFICATE_EXPIRATION] > 168h"
            "[BODY] == pat(*authentik*)"
          ];
        }
        {
          name = "Tautulli";
          group = "Sites (Media)";
          url = "https://tautulli.media.allanshomelab.com/api/v2?apikey=${secrets.tautulli_api_key}&cmd=status";
          conditions = [
            "[STATUS] == 200"
            "[CERTIFICATE_EXPIRATION] > 168h"
            "[BODY] == pat(*Ok*)"
          ];
        }
        {
          name = "Transmission";
          group = "Sites (Media)";
          url = "https://transmission.media.allanshomelab.com/transmission/web/";
          conditions = [
            "[STATUS] == 200"
            "[CERTIFICATE_EXPIRATION] > 168h"
            "[BODY] == pat(*Transmission*)"
          ];
        }
      # {
      #   name = "KVM (Maturin)";
      #   group = "Sites (KVM)";
      #   url = "https://maturin.kvm.allanshomelab.com";
      #   conditions = [
      #     "[STATUS] == 200"
      #     "[CERTIFICATE_EXPIRATION] > 168h"
      #     "[BODY] == pat(*JetKVM*)"
      #   ];
      # }
      {
        name = "Nginx";
        group = "Sites (NixOS)";
        url = "https://nginx.nixos.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[BODY] == pat(*nginx*)"
        ];
      }
      {
        name = "Authentik";
        group = "Sites (Allan's Home Lab)";
        url = "https://authn.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*authentik*)"
        ];
      }
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

