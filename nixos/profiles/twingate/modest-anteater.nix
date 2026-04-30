{ ... }:

{
  imports = [
    ../../modules/oci-containers/twingate.nix
  ];

  services.homelab.twingateConnector = {
    enable = true;
    connectorKey = "modestAnteater";
    networkName = "allanshomelab";
    image = "twingate/connector:1.88.0@sha256:7b366b2bdabbed7e8f51f4019f3b932c50078aaf021569b42be49160caab16ec";
  };
}