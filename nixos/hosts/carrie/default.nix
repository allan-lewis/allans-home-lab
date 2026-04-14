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

    ../../modules/oci-containers/it-tools.nix
    ../../modules/oci-containers/nginx.nix
    ../../modules/oci-containers/no-geeks-brewing.nix
    ../../modules/oci-containers/trilium.nix
    ../../modules/oci-containers/vaultwarden.nix
  ];

  networking.hostName = hostName;

  system.stateVersion = "25.11";
}