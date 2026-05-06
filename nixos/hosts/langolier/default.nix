{ versionCurrent, ... }:

let  
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/langolier.toml);
  nixosVersion = versionCurrent;
in
{
  _module.args = {
    hostAddress = inventoryConfig.network.ipv4.address;
    hostInterface = "enp2s0";
    hostName = inventoryConfig.hostname;
    nixosVersion = nixosVersion;
  };

  imports = [
    ../../_profiles/hosts/langolier
  ];

  system.stateVersion = nixosVersion;
}