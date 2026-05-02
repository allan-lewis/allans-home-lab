{ backupRemotePrefix, config, ... }:

let
  hostName = inventoryConfig.hostname;
  backupLocation = "${backupRemotePrefix}/${hostName}";
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/flagg.toml);
in
{
  _module.args = {
    backupRoot = backupLocation;
    hostAddress = inventoryConfig.network.ipv4.address;
    hostInterface = "eth1";
    hostName = hostName;
  };

  imports = [
    ../../profiles/hosts/flagg.nix
  ];

  system.stateVersion = "25.11";
}