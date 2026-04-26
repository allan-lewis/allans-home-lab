{ backupRemotePrefix, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/cujo.toml);

  hostName = inventoryConfig.hostname;
  backupLocation = "${backupRemotePrefix}/${hostName}";
in
{
  _module.args = {
    backupRoot = backupLocation;

    hostAddress = inventoryConfig.network.ipv4.address;
    hostInterface = "eth1";
    hostName = inventoryConfig.hostname;
  };

  imports = [
    ../../profiles/hosts/cujo.nix
  ];

  system.stateVersion = "25.11";
}