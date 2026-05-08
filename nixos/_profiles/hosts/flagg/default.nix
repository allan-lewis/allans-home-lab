{ backupRoot, hostAddress, hostName, hostInterface, ... }:

{
  imports = [
    ../../../_modules/bare-metal
    ../../../_modules/oci-containers/twingate
    ../../../_modules/tailscale

    ../../../_profiles/authentik
    ../../../_profiles/cloudflare
    ../../../_profiles/gatus
    ../../../_profiles/prometheus-stack
    ../../../_profiles/s3-mirror
    ../../../_profiles/traefik
    ../../../_profiles/twingate
  ];

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };

  services.homelab.managedState.schedule = "*:30";

  homelab.twingate = {
    enable = true;
    connectorName = "modestAnteater";
  };
}