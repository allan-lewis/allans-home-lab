{ backupRoot, hostName, ... }:

{
  imports = [
    ../virtual-machine.nix
    ../trilium.nix
    ../twingate/valiant-stingray.nix
    ../vaultwarden.nix

    ../../modules/oci-containers/homepage.nix
    ../../modules/oci-containers/it-tools.nix
    ../../modules/oci-containers/nginx.nix
    ../../modules/oci-containers/no-geeks-brewing.nix
  ];

  networking.hostName = hostName;

  homelab.managedStateSchedule = "*:10";
}