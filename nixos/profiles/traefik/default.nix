{ config, lib, pkgs, ... }:

let
  traefikServices = [
    {
      name = "129-monroe";
      host = "129monroe.com";
      url = "http://192.168.86.228:35550";
      authentik = false;
    }
    {
      name = "129-vault";
      host = "vault.129monroe.com";
      url = "http://192.168.86.228:35550";
      authentik = false;
    }
    {
      name = "alertmanager";
      host = "alertmanager.docker.allanshomelab.com";
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
      url = "http://192.168.86.228:3007";
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
      authentik = false;
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
      url = "http://192.168.86.219:8386";
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
      authentik = false;
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
      url = "http://192.168.86.219";
      authentik = false;
    }
    {
      name = "no-geeks-brewing";
      host = "nogeeksbrewing.com";
      url = "http://192.168.86.228:8080";
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
      host = "prometheus.docker.allanshomelab.com";
      url = "http://192.168.86.204:3072";
      authentik = false;
    }
    {
      name = "prowlarr";
      host = "prowlarr.media.allanshomelab.com";
      url = "http://192.168.86.224:9696";
      authentik = false;
    }
    {
      name = "radarr";
      host = "radarr.media.allanshomelab.com";
      url = "http://192.168.86.224:7878";
      authentik = false;
    }
    {
      name = "sonarr";
      host = "sonarr.media.allanshomelab.com";
      url = "http://192.168.86.224:8989";
      authentik = false;
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
    }
    {
      name = "whoami";
      host = "whoami.nixos.allanshomelab.com";
      url = "http://127.0.0.1:8180";
      authentik = false;
    }
  ];

  mkRouter = service: {
    entryPoints = [ "websecure" ];
    service = "service-${service.name}";
    rule = "Host(`${service.host}`)";
    middlewares = lib.optionals (service.authentik or false) [ "authentik" ];
    tls.certResolver = "myresolver";
  };

  mkService = service: {
    loadBalancer = {
      servers = [
        { url = service.url; }
      ];
      passHostHeader = true;
    };
  };
in
{
  sops.secrets.cloudflare_api_key = {
    sopsFile = ../../secrets/traefik.yaml;
    key = "CLOUDFLARE_API_KEY";
  };

  sops.templates."traefik.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      CLOUDFLARE_EMAIL=allan.e.lewis@gmail.com
      CLOUDFLARE_API_KEY=${config.sops.placeholder.cloudflare_api_key}
    '';
  };

  services.traefik = {
    enable = true;

    # ACME state lives here
    dataDir = "/var/lib/traefik";

    # used only for static config substitution
    environmentFiles = [ config.sops.templates."traefik.env".path ];

    staticConfigOptions = {
      api = {
        insecure = true;
      };

      entryPoints = {
        websecure.address = ":443";
        traefik.address = ":8088";
      };

      providers.file = {
        watch = true;
      };

      certificatesResolvers.myresolver.acme = {
        dnsChallenge = {
          provider = "cloudflare";
        };
        email = "allan.e.lewis@gmail.com";
        storage = "${config.services.traefik.dataDir}/acme.json";
      };

      serversTransport.insecureSkipVerify = true;
    };

    dynamicConfigOptions = {
      http = {
        routers =
          builtins.listToAttrs
            (map (service: {
              name = "router-${service.name}-https";
              value = mkRouter service;
            }) traefikServices);

        services =
          builtins.listToAttrs
            (map (service: {
              name = "service-${service.name}";
              value = mkService service;
            }) traefikServices);

        middlewares = {
          authentik = {
            forwardAuth = {
              address = "http://192.168.86.204:9180/outpost.goauthentik.io/auth/traefik";
              trustForwardHeader = true;
              authResponseHeaders = [
                "X-authentik-username"
                "X-authentik-groups"
                "X-authentik-email"
                "X-authentik-name"
                "X-authentik-uid"
                "X-authentik-jwt"
                "X-authentik-meta-jwks"
                "X-authentik-meta-outpost"
                "X-authentik-meta-provider"
                "X-authentik-meta-app"
                "X-authentik-meta-version"
                "authorization"
              ];
            };
          };
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 443 8088 ];

  virtualisation.oci-containers = {
    backend = "podman";

    containers.whoami = {
      image = "traefik/whoami:latest";
      pull = "missing";
      ports = [
        "127.0.0.1:8180:80/tcp"
      ];
      extraOptions = [
        "--replace"
      ];
    };
  };

  services.traefik.staticConfigOptions = {
    log = {
      level = "INFO";
    };
    accessLog = {
      format = "json";
    };
  };
}