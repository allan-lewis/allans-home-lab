{ hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/oci-containers/it-tools
    ../../modules/oci-containers/nginx
    ../../modules/virtual-machine

    ../../profiles/homepage
    ../../profiles/trilium
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  services.homelab.managedState.schedule = "*:10";
}
