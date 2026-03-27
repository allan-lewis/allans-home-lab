{ config, lib, pkgs, ... }:

let
  traefikServices = [
    {
      name = "gatus";
      host = "gatus.nixos.allanshomelab.com";
      url = "http://192.168.86.219:8080";
      authentik = false;
    }
    {
      name = "it-tools";
      host = "tools.nixos.allanshomelab.com";
      url = "http://192.168.86.219:8386";
      authentik = false;
    }
    {
      name = "kvm-maturin";
      host = "maturin.kvm.allanshomelab.com";
      url = "http://192.168.86.248";
      authentik = false;
    }
    {
      name = "nginx";
      host = "nginx.nixos.allanshomelab.com";
      url = "http://192.168.86.219";
      authentik = false;
    }
    {
      name = "pihole";
      host = "dns.nixos.allanshomelab.com";
      url = "http://192.168.86.218";
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
              address = "http://192.168.86.205:9180/outpost.goauthentik.io/auth/traefik";
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