{ defaultSubnet, hostDns, hostIp4Address, hostIp4Gateway, hostInterface, hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/bare-metal
    ../../modules/oci-containers/frigate
  ];

  _module.args = {
    frigateStorageDir = "/data/frigate";
  };

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostIp4Address;
    gateway = hostIp4Gateway;
    dns = hostDns;
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/3f67dce7-25b8-4c3a-beee-f086750dd372";
    fsType = "ext4";
  };

}
