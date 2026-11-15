{ authentikHost, hostDns, hostIp4Address, hostIp4Gateway, hostInterface, hostName, nixosVersion, ... }:

{
  imports = [
    ./gatus.nix
    ./prometheus.nix
    ./traefik.nix

    ../../modules/bare-metal
    ../../modules/tailscale

    ../../profiles/authentik
    ../../profiles/cloudflare
    ../../profiles/prometheus-stack
    ../../profiles/s3-mirror
    ../../profiles/twingate
    ../../profiles/vaultwarden
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostIp4Address;
    gateway = hostIp4Gateway;
    dns = hostDns;
  };

  services.homelab.managedState.schedule = "*:30";

  #: castor is the source of truth for SLO windows up to 28d, so retain beyond the 14d default
  services.homelab.prometheus.retentionTime = "35d";

  homelab.twingate = {
    enable = true;
    connectorName = "modestAnteater";
  };

}

