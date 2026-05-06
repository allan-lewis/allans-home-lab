{ hostName, ... }:

{
  imports = [
    ../../../_modules/virtual-machine

    ../../../_profiles/media-acquisition
  ];

  networking.hostName = hostName;

  services.homelab.managedState.schedule = "*:50";
}