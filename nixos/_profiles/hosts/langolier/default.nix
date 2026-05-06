{ hostAddress, hostName, hostInterface, ... }:

{
  imports = [
    ../../../_modules/bare-metal

    ../../../_profiles/pihole
  ];

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };

}