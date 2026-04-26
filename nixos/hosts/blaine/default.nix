{ ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/blaine.toml);
in
{
  _module.args = {
    hostName = inventoryConfig.hostname;
  };

  imports = [
    ../../profiles/hosts/blaine.nix
  ];

  system.stateVersion = "25.11";
}