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
    image = "twingate/connector:1.85.0@sha256:5e126d3ce36aa20b8977bab0b7e3da90ba1e10476234020a81cbdaf02781136b";
  };

  system.stateVersion = "25.11";
}