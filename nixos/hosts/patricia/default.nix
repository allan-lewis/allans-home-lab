{ nasBasePath, versionCurrent, ... }:

let
  backupLocation = "${nasBasePath}/${hostName}";
  hostName = inventoryConfig.hostname;
  inventoryConfig = builtins.fromTOML(builtins.readFile ../../../inventory/hosts/patricia.toml);
  nixosVersion = versionCurrent;
in
{
  _module.args = {
    backupRoot = backupLocation;
    hostName = inventoryConfig.hostname;
    nixosVersion = nixosVersion;
  };

  imports = [
    ../../_profiles/hosts/patricia
  ];

  system.stateVersion = nixosVersion;
}