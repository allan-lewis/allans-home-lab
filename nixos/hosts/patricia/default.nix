{ backupRemotePrefix, lib, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/patricia.toml);
  hostName = inventoryConfig.hostname;
  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  _module.args = {
    nasRootFolder = defaultRemoteNasPerHostBackupVolume;
  };
  
  imports = [
    ../../profiles/base
    ../../profiles/media-acquisition
    ../../profiles/virtual-machine
  ];

  networking.hostName = hostName;

  homelab.managedStateSchedule = "*:40";

  system.stateVersion = "25.11";
}