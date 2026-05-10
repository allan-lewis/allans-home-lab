{ hostName, ... }:

{
  imports = [
    ../../../modules/virtual-machine

    ../../../profiles/media-acquisition
  ];

  networking.hostName = hostName;

  services.homelab.managedState.schedule = "*:50";
}