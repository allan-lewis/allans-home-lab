{ backupLocation, nasBasePath, versionCurrent, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/roland.toml);
  hostName = inventoryConfig.hostname;
  nixosVersion = versionCurrent;
in
{
  _module.args = {
    backupRoot = backupLocation;
    hostAddress = inventoryConfig.network.ipv4.address;
    hostInterface = "enp4s0";
    hostName = inventoryConfig.hostname;
    hostTimeZone = "America/New_York";
    nixosVersion = nixosVersion;
  };

  imports = [
    ../../profiles/hosts/roland
  ];

  system.stateVersion = nixosVersion;
}