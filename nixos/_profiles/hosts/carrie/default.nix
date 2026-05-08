{ hostName, ... }:

{
  imports = [
    ../../../_modules/oci-containers/it-tools
    ../../../_modules/oci-containers/nginx
    ../../../_modules/virtual-machine

    ../../../_profiles/no-geeks-brewing
    ../../../_profiles/twingate

    # ../trilium.nix
    # ../vaultwarden.nix
    # ../../modules/oci-containers/homepage.nix
    # ../../modules/oci-containers/no-geeks-brewing.nix
  ];

  networking.hostName = hostName;

  services.homelab.managedState.schedule = "*:10";

  homelab.twingate = {
    enable = true;
    connectorName = "valiantStingray";
  };
}