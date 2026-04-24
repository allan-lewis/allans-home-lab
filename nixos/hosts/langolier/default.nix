{ config, lib, ... }:

let  
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/langolier.toml);
in
{
  _module.args = {
    hostAddress = inventoryConfig.network.ipv4.address;
    hostInterface = "enp2s0";
    hostName = inventoryConfig.hostname;
  };

  imports = [
    ../../profiles/hosts/langolier.nix
  ];

  system.stateVersion = "25.11";
}