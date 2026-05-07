{ config, lib, pkgs, ... }:

let
  traefikServices = [

  ];

  mkRouter = service: {
    entryPoints = [ "websecure" ];
    service = "service-${service.name}";
    rule =
      if service ? excludeAdmin && service.excludeAdmin
      then "Host(`${service.host}`) && !PathPrefix(`/admin`)"
      else "Host(`${service.host}`)";
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
    sopsFile = ./secrets/traefik.yaml;
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

    dataDir = "/var/lib/traefik";

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
      image = "traefik/whoami:v1.11@sha256:200689790a0a0ea48ca45992e0450bc26ccab5307375b41c84dfc4f2475937ab";
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