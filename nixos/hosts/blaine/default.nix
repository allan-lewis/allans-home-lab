{ lib, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/blaine.toml);
  hostName = inventoryConfig.hostname;
in
{
  imports = [
    ../../profiles/base
    ../../profiles/openvpn
    ../../profiles/virtual-machine
  ];

  networking.hostName = hostName;

  services.homelab.managedState.enable = lib.mkForce false;

  system.stateVersion = "25.11";
}