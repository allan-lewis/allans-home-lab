{ lib, ... }:

{
  services.homelab.containers.homelab-metrics = {
    image = "allanelewis/homelab-metrics:v2026.07.0@sha256:e19acc00c52741bfab0acba6248e4c56e75866c042f605d1bffb636a216dfa46";

    port = 9102;

    environment = {
      ENABLE_NIXOS_METRICS = "true";
    };

    volumes = [
      "/nix/var/nix/profiles:/nix/var/nix/profiles:ro"
      "/run:/run:ro"
    ];

  };

  virtualisation.oci-containers.containers.homelab-metrics = {
    ports = lib.mkForce [];
    extraOptions = [
      "--network=host"
    ];
  };
}
