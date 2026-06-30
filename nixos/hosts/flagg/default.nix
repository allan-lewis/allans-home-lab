{ hostIp4Address, hostInterface, hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/bare-metal
    ../../modules/oci-containers/twingate
    ../../modules/tailscale

    ../../profiles/authentik
    ../../profiles/cloudflare
    ../../profiles/gatus
    ../../profiles/homelab-dashboard
    ../../profiles/prometheus-stack
    ../../profiles/s3-mirror
    ../../profiles/traefik
    ../../profiles/twingate
    ../../profiles/vaultwarden
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostIp4Address;
  };

  services.homelab.managedState.schedule = "*:30";

  homelab.twingate = {
    enable = true;
    connectorName = "modestAnteater";
  };
}
