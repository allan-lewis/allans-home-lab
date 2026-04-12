{ backupRemotePrefix, lib, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/patricia.toml);
  hostName = inventoryConfig.hostname;
  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  imports = [
    ../../profiles/base
    ../../profiles/virtual-machine
  ];

  networking.hostName = hostName;

  services.homelab.managedState.enable = lib.mkForce false;

  system.stateVersion = "25.11";
}