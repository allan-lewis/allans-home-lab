{ hostName, ... }:

{
  imports = [
    ../../../modules/oci-containers/it-tools
    ../../../modules/oci-containers/nginx
    ../../../modules/virtual-machine

    ../../../profiles/homepage
    ../../../profiles/no-geeks-brewing
    ../../../profiles/trilium
    ../../../profiles/twingate
    ../../../profiles/vaultwarden
  ];

  networking.hostName = hostName;

  services.homelab.managedState.schedule = "*:10";

  homelab.twingate = {
    enable = true;
    connectorName = "valiantStingray";
  };
}