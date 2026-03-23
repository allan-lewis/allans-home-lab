{ lib, ... }:

let
  hostName = "langolier";
in
{
  imports = [
    ../../profiles/bare-metal
    ../../profiles/base
    ../../profiles/pihole
  ];

  networking.hostName = hostName;

  homelab.bareMetal.interface = "enp2s0";
  homelab.bareMetal.address = "192.168.86.218";

  services.homelab.managedState.enable = lib.mkForce false;

  system.stateVersion = "25.11";
}