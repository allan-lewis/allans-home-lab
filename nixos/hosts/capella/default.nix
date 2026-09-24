{ defaultSubnet, hostDns, hostIp4Address, hostIp4Gateway, hostInterface, hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/bare-metal

    ../../profiles/openvpn-gateway
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostIp4Address;
    gateway = hostIp4Gateway;
    dns = hostDns;
  };

  services.homelab.vpnKillSwitch = {
    wanInterface = hostInterface;
   
    lanSubnets = [ defaultSubnet ];

    # lanSubnets = [ "192.168.10.0/24" ];

    vpnEndpointIps = [
      "185.208.9.158"
      "185.208.9.189"
      "45.84.216.183"
      "45.84.216.83"
    ];
  };

}
