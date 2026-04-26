{ hostName, lib, ... }:

{
  imports = [
    ../openvpn
    ../virtual-machine.nix
  ];

  networking.hostName = hostName;

  services.homelab.managedState.enable = lib.mkForce false;
}