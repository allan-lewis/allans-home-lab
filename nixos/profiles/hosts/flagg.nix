{ hostAddress, hostName, hostInterface, ... }:

{
  imports = [
    ../bare-metal.nix

    ../gatus.nix
    ../traefik.nix
    ../twingate/modest-anteater.nix
  ];

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };
}