{ hostAddress, hostName, hostInterface, ... }:

{
  imports = [
    ../../../modules/bare-metal

    ../../../profiles/pihole
  ];

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };

}