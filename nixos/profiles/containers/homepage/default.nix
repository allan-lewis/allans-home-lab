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
      image = "ghcr.io/gethomepage/homepage@sha256:9627769818fbfb14147d3e633e57cef9c27c0c5f07585f5a1d6c3d3425b3b33c";
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