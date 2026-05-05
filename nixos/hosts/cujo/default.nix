{ nasBasePath, versionCurrent, ... }:

let
  backupLocation = "${nasBasePath}/${hostName}";
  hostName = inventoryConfig.hostname;
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/cujo.toml);
  nixosVersion = versionCurrent;
in
{
  _module.args = {
    backupRoot = backupLocation;
    hostAddress = inventoryConfig.network.ipv4.address;
    hostInterface = "eth1";
    hostName = inventoryConfig.hostname;
    nixosVersion = nixosVersion;
  };

  imports = [
    ../../_profiles/hosts/cujo
  ];

  system.stateVersion = versionCurrent;
}
