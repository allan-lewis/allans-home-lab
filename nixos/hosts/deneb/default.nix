{ hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/oci-containers/checkmk
    ../../modules/virtual-machine
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;
}
