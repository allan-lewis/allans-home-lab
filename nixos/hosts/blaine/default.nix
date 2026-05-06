{ versionCurrent, ... }:

let
  hostName = inventoryConfig.hostname;
  inventoryConfig = builtins.fromTOML(builtins.readFile ../../../inventory/hosts/blaine.toml);
  nixosVersion = versionCurrent;
in
{
  _module.args = {
    hostName = inventoryConfig.hostname;
    nixosVersion = nixosVersion;
  };

  imports = [
    ../../_profiles/hosts/blaine
  ];

  system.stateVersion = nixosVersion;
}