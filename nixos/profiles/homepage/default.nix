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
    image = "ghcr.io/gethomepage/homepage:v2.1.2@sha256:da9dca9ec258c628146bed1445da0853f2b88f0b10bafd97c091de807c363d60";
  };

  systemd.services.podman-homepage.restartTriggers = [
    homepageConfigSrc
  ];
}