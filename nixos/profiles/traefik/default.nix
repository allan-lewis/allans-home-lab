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

}
