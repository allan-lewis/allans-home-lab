{ config, ... }:

{
  imports = [
    ../../_modules/cloudflare
  ];

  sops.secrets.cloudflared_tunnel_token = {
    sopsFile = ./cloudflare.yaml;
    key = "cloudflared/tunnel_token";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.templates."cloudflared.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      CLOUDFLARE_TUNNEL_TOKEN=${config.sops.placeholder.cloudflared_tunnel_token}
    '';
  };

  services.homelab.cloudflaredTunnel = {
    enable = true;
    environmentFile = config.sops.templates."cloudflared.env".path;
  };
}