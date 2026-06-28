{ hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/virtual-machine
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  services.homelab.managedState.schedule = "*:10";
}
