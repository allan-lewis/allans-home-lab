{ backupRemotePrefix, config, pkgs, lib, ... }:


let
  cfg = config.homelab.bareMetal;
  
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/roland.toml);

  hostName = inventoryConfig.hostname;
  backupLocation = "${backupRemotePrefix}/${hostName}";
in
{
  _module.args = {
    backupRoot = backupLocation;
    hostName = inventoryConfig.hostname;
    ipAddress = inventoryConfig.network.ipv4.address;
  };

  imports = [
    ../../profiles/hosts/roland.nix

    ../../profiles/bare-metal.nix
    ../../profiles/desktop.nix
  ];

  system.stateVersion = "25.11";
}