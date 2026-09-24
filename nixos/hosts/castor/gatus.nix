{ ... }:

{
  imports = [
    ../../profiles/gatus
  ];


  homelab.gatus.endpoints = secrets: [
    ## HOSTS
    {
      name = "Bellatrix (NixOS DevOps)";
      group = "Hosts";
      enabled = true;
      url = "icmp://bellatrix.ip.allanshomelab.com";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Canopus (Local Backup)";
      group = "Hosts";
      enabled = true;
      url = "icmp://canopus.ip.allanshomelab.com";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Capella (NixOS VPN)";
      group = "Hosts";
      enabled = true;
      url = "icmp://capella.ip.allanshomelab.com";
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
      name = "Polaris (NAS)";
      group = "Hosts";
      enabled = true;
      url = "icmp://polaris.ip.allanshomelab.com";
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
      name = "Procyon (Home Automation)";
      group = "Hosts";
      enabled = true;
      url = "icmp://procyon.ip.allanshomelab.com";
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
      name = "Sirius (Hypervisor)";
      group = "Hosts";
      enabled = true;
      url = "icmp://sirius.ip.allanshomelab.com";
      conditions = [ "[CONNECTED] == true" ];
    }
    ## SITES (MEDIA)
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
    ## SITES (NIXOS)
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
      name = "Nginx";
      group = "Sites (NixOS)";
      url = "https://nginx.nixos.allanshomelab.com";
      conditions = [
        "[STATUS] == 200"
        "[BODY] == pat(*nginx*)"
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
      name = "Whoami";
      group = "Sites (NixOS)";
      url = "https://whoami.nixos.allanshomelab.com";
      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
        "[BODY] == pat(*whoami.nixos.allanshomelab.com*)"
      ];
    }
    {
      name = "Canopus";
      group = "Sites (Hosts)";
      url = "https://canopus.hosts.allanshomelab.com";
      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
        "[BODY] == pat(*portal*)"
      ];
    }
      {
        name = "Sirius";
        group = "Sites (Hosts)";
        url = "https://sirius.hosts.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Proxmox*)"
        ];
      }
      {
        name = "Polaris";
        group = "Sites (Hosts)";
        url = "https://polaris.hosts.allanshomelab.com/ui/";
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
        name = "Home Assistant";
        group = "Sites (Allan's Home Lab)";
        url = "https://home.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*Home Assistant*)"
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
        name = "KVM (Sirius)";
        group = "Sites (KVM)";
        url = "https://sirius.kvm.allanshomelab.com";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
          "[BODY] == pat(*JetKVM*)"
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

}
