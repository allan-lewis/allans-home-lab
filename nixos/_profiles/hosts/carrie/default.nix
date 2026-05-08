{ hostName, ... }:

{
  imports = [
    ../../../_modules/oci-containers/it-tools
    ../../../_modules/oci-containers/nginx
    ../../../_modules/virtual-machine

    ../../../_profiles/homepage
    ../../../_profiles/no-geeks-brewing
    ../../../_profiles/trilium
    ../../../_profiles/twingate
    # ../../../_profiles/vaultwarden
  ];

  networking.hostName = hostName;

  services.homelab.managedState.schedule = "*:10";

  homelab.twingate = {
    enable = true;
    connectorName = "valiantStingray";
  };
}