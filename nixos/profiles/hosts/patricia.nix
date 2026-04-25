{ backupRoot, hostName, ... }:

{
  imports = [
    ../media-acquisition.nix
    ../virtual-machine.nix
  ];

  networking.hostName = hostName;

  homelab.managedStateSchedule = "*:50";
}