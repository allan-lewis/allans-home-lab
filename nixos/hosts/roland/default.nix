{ backupRemotePrefix, config, pkgs, lib, ... }:


let
  cfg = config.homelab.bareMetal;
  
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/roland.toml);
  
  hostName = inventoryConfig.hostname;
  ipAddress = inventoryConfig.network.ipv4.address;

  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  imports = [
    ../../profiles/bare-metal.nix
    ../../profiles/desktop.nix
  ];

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = "enp4s0";
    address = ipAddress;
  };

  time.timeZone = lib.mkForce "America/New_York";

  system.stateVersion = "25.11";
}