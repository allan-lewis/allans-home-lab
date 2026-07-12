{ hostIp4Address, hostName, hostInterface, nixosVersion, ... }:

{
  imports = [
    ../../modules/bare-metal

    ../../profiles/pihole
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostIp4Address;
  };
}