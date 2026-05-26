{
  services.homelab.containers.homelab-metrics = {
    image = "docker.io/allanelewis/homelab-metrics:v2026.05.1@sha256:ade6c0e969afde26b0c63b37f23844f4c23d213a90545311288eeb2f61f41c40";

    port = 9102;

    environment = {
      ENABLE_NIXOS_METRICS = "true";
    };

    volumes = [
      "/nix/store:/nix/store:ro"
      "/nix/var/nix/profiles:/nix/var/nix/profiles:ro"
      "/run/current-system:/run/current-system:ro"
      "/run/booted-system:/run/booted-system:ro"
    ];
  };
}
