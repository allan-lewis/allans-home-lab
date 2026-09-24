{ hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/virtual-machine
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;
}
