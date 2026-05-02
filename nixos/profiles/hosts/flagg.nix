{ hostAddress, hostName, hostInterface, ... }:

{
  imports = [
    ../bare-metal.nix

    ../gatus.nix
    ../traefik.nix
  ];

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };
}