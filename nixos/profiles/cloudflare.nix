{ ... }:

{
  imports = [
    ../modules/cloudflare
  ];

  services.homelab.cloudflaredTunnel = {
    enable = true;
  };
}