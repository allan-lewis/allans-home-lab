{ lib, ... }:

let
  hostName = "langolier";
in
{
  imports = [
    ../../profiles/bare-metal
    ../../profiles/base
    ../../profiles/containers/twingate
    ../../profiles/pihole
  ];

  networking.hostName = hostName;

  homelab.bareMetal.interface = "enp2s0";
  homelab.bareMetal.address = "192.168.86.218";

  services.homelab.managedState.enable = lib.mkForce false;

  services.homelab.twingateConnector = {
    enable = true;
    connectorKey = "valiantStingray";
    networkName = "allanshomelab";
    image = "twingate/connector:1.85.0@sha256:21d71de5d6605936e23b1d15f268b1d94b68de685f7b51603b99e17c180002cb";
  };

  system.stateVersion = "25.11";
}