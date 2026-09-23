{ authentikHost, hostDns, hostIp4Address, hostIp4Gateway, hostInterface, hostName, nixosVersion, ... }:

{
  imports = [
    ./gatus.nix
    ./traefik.nix

    ../../modules/bare-metal
    ../../modules/tailscale

    ../../profiles/authentik
    ../../profiles/cloudflare
    ../../profiles/homelab-dashboard
    ../../profiles/homepage
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

  homelab.twingate = {
    enable = true;
    connectorName = "modestAnteater";
  };

}

