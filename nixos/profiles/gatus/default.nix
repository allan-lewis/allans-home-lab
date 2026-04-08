{ config, lib, ... }:

let
  endpoints = [
    {
      name = "Barlow (Ubuntu Sandbox)";
      group = "Hosts";
      enabled = false;
      url = "icmp://192.168.86.213";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Blaine (NixOS OpenVPN Gateway)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.222";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Callahan (Arch Sandbox, BTW)";
      group = "Hosts";
      enabled = false;
      url = "icmp://192.168.86.214";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Carrie (NixOS Apps)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.228";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Christine (Windows 11)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.212";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Cujo (NixOS DevOps)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.219";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Dandelo (Retro Gaming)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.217";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Derry (Local Backup)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.210";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Flagg (NixOS Core)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.204";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Gan (MacOS)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.211";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Gilead (Remote Backup)";
      group = "Hosts";
      enabled = true;
      url = "icmp://100.95.108.6";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Langolier (NixOS Pi-hole)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.218";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Maturin (Proxmox Hypervisor)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.200";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Misery (NixOS Media)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.227";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Overlook (Home Automation)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.229";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Patricia (NixOS R Stack)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.224";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Pennywise (NAS)";
      group = "Hosts";
      enabled = true;
      url = "icmp://192.168.86.220";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Roland (NixOS Daily Driver)";
      group = "Hosts";
      url = "icmp://192.168.86.206";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "Todash (NixOS Sandbox)";
      group = "Hosts";
      enabled = false;
      url = "icmp://192.168.86.216";
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
      name = "Pi-hole";
      group = "Sites (NixOS)";
      url = "https://dns.nixos.allanshomelab.com/admin";
      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
        "[BODY] == pat(*Pi-hole*)"
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
    {
      name = "Derry";
      group = "Sites (Hosts)";
      url = "https://derry.hosts.allanshomelab.com";
      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
        "[BODY] == pat(*portal*)"
      ];
    }
    {
      name = "Maturin";
      group = "Sites (Hosts)";
      url = "https://maturin.hosts.allanshomelab.com";
      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
        "[BODY] == pat(*Proxmox*)"
      ];
    }
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
      name = "Gilead";
      group = "Sites (Hosts)";
      url = "https://gilead.hosts.allanshomelab.com/ui/";
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
        "[BODY] == pat(*authentik*)"
      ];
    }
    {
      name = "Allan's Home Lab (www)";
      group = "Sites (Allan's Home Lab)";
      url = "https://www.allanshomelab.com";
      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
        "[BODY] == pat(*authentik*)"
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
        "[BODY] == pat(*No Geeks Brewing*)"
      ];
    }
    {
      name = "Public Website (www)";
      group = "Sites (No Geeks Brewing)";
      url = "https://www.nogeeksbrewing.com";
      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
        "[BODY] == pat(*No Geeks Brewing*)"
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
        "[BODY] == pat(*OK*)"
      ];
    }
    {
      name = "Homepage";
      group = "Sites (NixOS)";
      url = "https://homepage.nixos.allanshomelab.com";
      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
        "[BODY] == pat(*Homepage*)"
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
        "[BODY] == pat(*OK*)"
      ];
    }
    {
      name = "Radarr";
      group = "Sites (Media)";
      url = "https://radarr.media.allanshomelab.com/ping";
      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
        "[BODY] == pat(*OK*)"
      ];
    }
    {
      name = "Lidarr";
      group = "Sites (Media)";
      url = "https://lidarr.media.allanshomelab.com/ping";
      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
        "[BODY] == pat(*OK*)"
      ];
    }
    {
      name = "Bazarr";
      group = "Sites (Media)";
      url = "https://bazarr.media.allanshomelab.com";
      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
        "[BODY] == pat(*Bazarr*)"
      ];
    }
    {
      name = "Tautulli";
      group = "Sites (Media)";
      url = "https://tautulli.media.allanshomelab.com/api/v2?apikey=${config.sops.placeholder.tautulli_api_key}&cmd=status";
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
    {
      name = "KVM (Maturin)";
      group = "Sites (KVM)";
      url = "https://maturin.kvm.allanshomelab.com";
      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
        "[BODY] == pat(*JetKVM*)"
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

  gatusConfig = {
    metrics = true;
    storage = {
      type = "sqlite";
      path = "/var/lib/gatus/data.db";
    };
    inherit endpoints;
  };
in
{
  sops.secrets.tautulli_api_key = {
    sopsFile = ../../secrets/gatus.yaml;
    key = "TAUTULLI_API_KEY";
  };

  sops.templates."gatus.yaml" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = lib.generators.toYAML { } gatusConfig;
  };

  services.gatus = {
    enable = true;
    openFirewall = true;
    configFile = config.sops.templates."gatus.yaml".path;
  };

  systemd.services.gatus.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = lib.mkForce "root";
    Group = lib.mkForce "root";
  };
}