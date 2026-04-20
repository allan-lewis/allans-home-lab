{ hostAddress, hostName, hostInterface, hostTimeZone, lib, ... }:

{
  imports = [
    ../bare-metal.nix
    ../desktop.nix
  ];

  time.timeZone = lib.mkForce hostTimeZone;

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };
}