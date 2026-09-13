{ hostIp4Address, hostIp4Gateway, hostName, hostInterface, nixosVersion, ... }:

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
    gateway = hostIp4Gateway;
  };
}
