{ nasBasePath, versionCurrent, ... }:

let
  backupLocation = "${nasBasePath}/${hostName}";
  hostName = inventoryConfig.hostname;
  inventoryConfig = builtins.fromTOML(builtins.readFile ../../../inventory/hosts/misery.toml);
  nixosVersion = versionCurrent;
in
{
  _module.args = {
    backupRoot = backupLocation;
    hostName = inventoryConfig.hostname;
    hostAddress = inventoryConfig.network.ipv4.address;
    mediaLibraryDir = "/data/media-library";
    nixosVersion = nixosVersion;
  };

  imports = [
    ../../profiles/hosts/misery
  ];

  system.stateVersion = nixosVersion;
}