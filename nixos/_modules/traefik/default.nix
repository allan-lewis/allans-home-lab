{ config, lib, pkgs, ... }:

let
  inherit (lib) mkForce mkIf mkOption optionalAttrs optionals types;

  cfg = config.homelab.traefik;

  cloudflareApiKey = cfg.cloudflareApiKey config.sops.placeholder;

  mkRouter = service: {
    entryPoints = [ "websecure" ];
    service = "service-${service.name}";
    rule =
      if service.excludeAdmin
      then "Host(`${service.host}`) && !PathPrefix(`/admin`)"
      else "Host(`${service.host}`)";
    middlewares = optionals (service.authentik && cfg.authentikIpAddress != null) [ "authentik" ];
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

  authentikMiddlewares = optionalAttrs (cfg.authentikIpAddress != null) {
    authentik.forwardAuth = {
      address = "http://${cfg.authentikIpAddress}:9180/outpost.goauthentik.io/auth/traefik";
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
in
{
  options.homelab.traefik = {
    email = mkOption {
      type = types.str;
      description = "Email address used for Cloudflare/ACME.";
    };

    cloudflareApiKey = mkOption {
      type = types.functionTo types.str;
      description = "Function that returns the Cloudflare API key placeholder from SOPS placeholders.";
    };

    authentikIpAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional Authentik IP address. If null, the Authentik middleware is not created.";
    };

    services = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption { type = types.str; };
          host = mkOption { type = types.str; };
          url = mkOption { type = types.str; };

          authentik = mkOption {
            type = types.bool;
            default = false;
          };

          excludeAdmin = mkOption {
            type = types.bool;
            default = false;
          };
        };
      });
      default = [];
      description = "Traefik service/router definitions.";
    };
  };

  config = {
    sops.templates."traefik.env" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        CLOUDFLARE_EMAIL=${cfg.email}
        CLOUDFLARE_API_KEY=${cloudflareApiKey}
      '';
    };

    services.traefik = {
      enable = true;

      dataDir = "/var/lib/traefik";

      environmentFiles = [ config.sops.templates."traefik.env".path ];

      staticConfigOptions = {
        api.insecure = true;

        entryPoints = {
          websecure.address = ":443";
          traefik.address = ":8088";
        };

        providers.file.watch = true;

        certificatesResolvers.myresolver.acme = {
          dnsChallenge.provider = "cloudflare";
          email = cfg.email;
          storage = "${config.services.traefik.dataDir}/acme.json";
        };

        serversTransport.insecureSkipVerify = true;

        log.level = "INFO";

        accessLog.format = "json";
      };

      dynamicConfigOptions.http = {
        routers =
          builtins.listToAttrs
            (map (service: {
              name = "router-${service.name}-https";
              value = mkRouter service;
            }) cfg.services);

        services =
          builtins.listToAttrs
            (map (service: {
              name = "service-${service.name}";
              value = mkService service;
            }) cfg.services);

        middlewares = authentikMiddlewares;
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
  };
}