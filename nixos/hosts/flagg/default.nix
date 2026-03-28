{ lib, ... }:

let
  hostName = "flagg";
in
{
  imports = [
    ../../profiles/bare-metal
    ../../profiles/base
    ../../profiles/cloudflare
    ../../profiles/gatus
    ../../profiles/containers/twingate
    ../../profiles/tailscale
  ];

  networking.hostName = hostName;

  homelab.bareMetal.interface = "eth1";
  homelab.bareMetal.address = "192.168.86.204";

  services.homelab.managedState.enable = lib.mkForce false;

  services.homelab.twingateConnector = {
    enable = true;
    connectorKey = "modestAnteater";
    networkName = "allanshomelab";
  };

  services.homelab.cloudflaredTunnel = {
    enable = true;
  };

  system.stateVersion = "25.11";
}