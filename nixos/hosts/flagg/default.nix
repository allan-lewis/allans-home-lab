{ nasBasePath, versionCurrent, ... }:

let
  backupLocation = "${nasBasePath}/${hostName}";
  hostName = inventoryConfig.hostname;
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/flagg.toml);
  nixosVersion = versionCurrent;
in
{
  _module.args = {
    backupRoot = backupLocation;
    hostAddress = inventoryConfig.network.ipv4.address;
    hostInterface = "eth1";
    hostName = hostName;
    nixosVersion = nixosVersion;
  };

  imports = [
    ../../profiles/hosts/flagg
  ];

  system.stateVersion = nixosVersion;
}