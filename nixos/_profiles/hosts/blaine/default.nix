{ hostName, ... }:

{
  imports = [
    ../../../_modules/virtual-machine

    ../../../_profiles/openvpn-gateway
  ];

  networking.hostName = hostName;
}