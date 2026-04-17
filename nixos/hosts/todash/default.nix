{ backupRemotePrefix, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/todash.toml);
  hostName = inventoryConfig.hostname;
  backupLocation = "${backupRemotePrefix}/${hostName}";
in
{
  _module.args = {
    backupRoot = backupLocation;
    hostName = inventoryConfig.hostname;
  };

  imports = [
    ../../profiles/hosts/todash.nix

    ../../profiles/virtual-machine.nix
  ];

  system.stateVersion = "25.11";
}