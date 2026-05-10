{ config, lib, ... }:

{
  sops.secrets.tailscale_authkey = {
    sopsFile = ./tailscale.yaml;
    key = "tailscale_authkey";
    path = "/run/secrets/tailscale-authkey";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale-authkey";
    extraUpFlags = [
      "--accept-dns=true"
    ];
  };

  networking.firewall.trustedInterfaces =
    lib.mkIf config.services.tailscale.enable [ "tailscale0" ];
}