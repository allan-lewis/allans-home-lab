{ backupRemotePrefix, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/misery.toml);
  hostName = inventoryConfig.hostname;
  backupLocation = "${backupRemotePrefix}/${hostName}";
in
{
  # _module.args = {
  #   nasRootFolder = defaultRemoteNasPerHostBackupVolume;
  # };
  
  # imports = [
  #   ../../profiles/base
  #   ../../profiles/immich.nix
  #   ../../profiles/virtual-machine

  #   ../../modules/oci-containers/jellyfin.nix
  #   ../../modules/oci-containers/plex.nix
  #   ../../modules/oci-containers/tautulli.nix
  # ];

  # homelab.managedStateSchedule = "*:40";

  # networking.hostName = hostName;

  _module.args = {
    backupRoot = backupLocation;
    hostName = inventoryConfig.hostname;
    hostAddress = inventoryConfig.network.ipv4.address;
    mediaLibraryDir = "/data/media-library";
  };

  imports = [
    ../../profiles/hosts/misery.nix
  ];

  system.stateVersion = "25.11";
}