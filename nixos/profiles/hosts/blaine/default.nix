{ hostName, ... }:

{
  imports = [
    ../../../modules/virtual-machine

    ../../../profiles/openvpn-gateway
  ];

  networking.hostName = hostName;
}