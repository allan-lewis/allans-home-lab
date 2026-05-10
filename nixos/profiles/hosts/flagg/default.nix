{ backupRoot, hostAddress, hostName, hostInterface, ... }:

{
  imports = [
    ../../../modules/bare-metal
    ../../../modules/oci-containers/twingate
    ../../../modules/tailscale

    ../../../profiles/authentik
    ../../../profiles/cloudflare
    ../../../profiles/gatus
    ../../../profiles/prometheus-stack
    ../../../profiles/s3-mirror
    ../../../profiles/traefik
    ../../../profiles/twingate
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