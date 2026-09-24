{ defaultNasHost, hostDns, hostIp4Address, hostIp4Gateway, hostInterface, hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/bare-metal
    ../../modules/tailscale

    ../../profiles/media-acquisition
  ];

  _module.args.defaultNasHost = defaultNasHost;

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostIp4Address;
    gateway = hostIp4Gateway;
    dns = hostDns;
  };

  services.homelab.managedState.schedule = "*:50";
}
