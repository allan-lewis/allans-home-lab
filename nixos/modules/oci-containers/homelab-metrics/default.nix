{ lib, ... }:

{
  services.homelab.containers.homelab-metrics = {
    image = "allanelewis/homelab-metrics:v2026.06.2@sha256:73d7d674df37325dc8347327dc451935ded7a23a6b5070eb46b7ca9ffee349b7";

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
