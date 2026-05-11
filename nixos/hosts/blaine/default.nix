{ hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/virtual-machine

    ../../profiles/openvpn-gateway
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;
}