{ backupRemotePrefix, lib, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/patricia.toml);
  hostName = inventoryConfig.hostname;
  backupLocation = "${backupRemotePrefix}/${hostName}";
in
{
  _module.args = {
    backupRoot = backupLocation;
    hostName = inventoryConfig.hostname;
  };

  imports = [
    ../../profiles/hosts/patricia.nix
  ];

  system.stateVersion = "25.11";
}