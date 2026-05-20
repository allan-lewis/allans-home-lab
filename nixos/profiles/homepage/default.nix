{ config, pkgs, ... }:

let
  homepageConfigSrc = ./config;
in
{
  imports = [
    ../../modules/oci-containers/homepage
  ];

  sops.secrets.homepage_env = {
    sopsFile = ./homepage.env;
    format = "dotenv";
    key = "";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/homepage 0755 root root -"
    "d /var/lib/homepage/config 0755 root root -"
    "d /var/lib/homepage/config/logs 0755 root root -"
  ];

  system.activationScripts.homepage-config = {
    text = ''
      mkdir -p /var/lib/homepage/config
      mkdir -p /var/lib/homepage/config/logs

      ${pkgs.rsync}/bin/rsync -a --delete \
        --exclude logs/ \
        ${homepageConfigSrc}/ /var/lib/homepage/config/
    '';
  };

  services.homelab.homepage = {
    enable = true;
    port = 3007;
    configDir = "/var/lib/homepage/config";
    allowedHosts = "homepage.nixos.allanshomelab.com,allanshomelab.com";
    environmentFile = config.sops.secrets.homepage_env.path;
    image = "ghcr.io/gethomepage/homepage:v1.13.1@sha256:d8d784e5090111b6e4c56dfd90e272d2953a2094e87349f647165df0fa6c4401";
  };

  systemd.services.podman-homepage.restartTriggers = [
    homepageConfigSrc
  ];
}