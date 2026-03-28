{ lib, ... }:

let
  hostName = "flagg";
in
{
  imports = [
    ../../profiles/authentik
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

  services.homelab.authentikCompose = {
    enable = true;
    version = "2025.10.3";
    httpPort = 9180;
    httpsPort = 9143;
  };

  system.stateVersion = "25.11";
}