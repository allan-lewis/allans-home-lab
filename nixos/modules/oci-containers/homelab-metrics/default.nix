{ lib, ... }:

{
  services.homelab.containers.homelab-metrics = {
    image = "allanelewis/homelab-metrics:v2026.06.0@sha256:c53e10fd8423a8b768f712615c37a9a03fbcceb4cc6fe20d33f9ddc0a9ba7ecf";

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
