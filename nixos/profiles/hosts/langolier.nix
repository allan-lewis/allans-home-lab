{ hostAddress, hostName, hostInterface, lib, ... }:

{
  imports = [
    ../bare-metal.nix
    
    ../../modules/pihole.nix
  ];

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };

  services.homelab.managedState.enable = lib.mkForce false;
}