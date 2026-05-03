{ nasBasePath, versionCurrent, ... }:

let
  backupLocation = "${nasBasePath}/${hostName}";
  hostName = inventoryConfig.hostname;
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/todash.toml);
  nixosVersion = versionCurrent;
in
{
  _module.args = {
    backupRoot = backupLocation;
    hostName = inventoryConfig.hostname;
    nixosVersion = nixosVersion;
  };

  imports = [
    ../../_profiles/hosts/todash
  ];

  system.stateVersion = nixosVersion;
}
