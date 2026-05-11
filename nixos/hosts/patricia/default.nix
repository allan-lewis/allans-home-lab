{ hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/virtual-machine

    ../../profiles/media-acquisition
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  services.homelab.managedState.schedule = "*:50";
}