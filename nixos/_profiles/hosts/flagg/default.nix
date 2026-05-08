{ backupRoot, hostAddress, hostName, hostInterface, ... }:

{
  imports = [
    ../../../_modules/bare-metal
    ../../../_modules/tailscale

    ../../../_profiles/authentik
    ../../../_profiles/cloudflare
    ../../../_profiles/gatus
    ../../../_profiles/prometheus-stack
    ../../../_profiles/s3-mirror
    ../../../_profiles/traefik

    # ../twingate/modest-anteater.nix
  ];

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };

  services.homelab.managedState.schedule = "*:30";
}