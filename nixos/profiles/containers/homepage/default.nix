{ config, lib, pkgs, ... }:

let
  homepageConfigSrc = ../../../assets/homepage;
in
{
  sops.secrets.homepage_env = {
    sopsFile = ../../../secrets/homepage.env;
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

  virtualisation.oci-containers = {
    backend = "podman";

    containers.homepage = {
      image = "ghcr.io/gethomepage/homepage:v1.12.3@sha256:cc84f2f5eb3c7734353701ccbaa24ed02dacb0d119114e50e4251e2005f3990a";
      autoStart = true;

      ports = [
        "3007:3000"
      ];

      volumes = [
        "/var/lib/homepage/config:/app/config"
      ];

      environment = {
        HOMEPAGE_ALLOWED_HOSTS =
          "homepage.nixos.allanshomelab.com,allanshomelab.com";
      };

      environmentFiles = [
        config.sops.secrets.homepage_env.path
      ];

      extraOptions = [
        "--pull=newer"
        "--replace"
        "--health-cmd=none"
      ];
    };
  };

  systemd.services.podman-homepage = {
    serviceConfig.ExecStartPre = [
      "${pkgs.coreutils}/bin/mkdir -p /var/lib/homepage/config/logs"
    ];

    restartTriggers = [
      homepageConfigSrc
      config.sops.secrets.homepage_env.path
    ];
  };
}