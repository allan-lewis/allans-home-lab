{ hostDns, hostIp4Address, hostIp4Gateway, hostInterface, hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/bare-metal
    ../../modules/oci-containers/frigate
    ../../modules/oci-containers/it-tools
    ../../modules/oci-containers/nginx
    ../../modules/tailscale

    ../../profiles/homelab-dashboard
    ../../profiles/homepage
    ../../profiles/immich
    ../../profiles/trilium
    ../../profiles/twingate
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostIp4Address;
    gateway = hostIp4Gateway;
    dns = hostDns;
  };

  services.homelab.managedState.schedule = "*:10";

  homelab.twingate = {
    enable = true;
    connectorName = "valiantStingray";
  };

}
