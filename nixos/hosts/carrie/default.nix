{ backupRemotePrefix, lib, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/carrie.toml);
  hostName = inventoryConfig.hostname;
  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  _module.args = {
    nasRootFolder = defaultRemoteNasPerHostBackupVolume;
  };
  
  imports = [
    ../../profiles/base
    ../../profiles/virtual-machine

    ../../modules/trilium.nix
    ../../modules/vaultwarden.nix
  ];

  networking.hostName = hostName;

  system.stateVersion = "25.11";
}