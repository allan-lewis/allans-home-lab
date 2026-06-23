{ lib, ... }:

{
  services.homelab.containers.homelab-metrics = {
    image = "allanelewis/homelab-metrics:v2026.06.1@sha256:3a099582379c6dd697f30ff189b6f1751a64ef5d874b928edb56bfb0a111511a";

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
