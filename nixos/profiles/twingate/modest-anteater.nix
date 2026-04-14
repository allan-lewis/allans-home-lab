{ ... }:

{
  imports = [
    ../../modules/oci-containers/twingate.nix
  ];

  services.homelab.twingateConnector = {
    enable = true;
    connectorKey = "modestAnteater";
    networkName = "allanshomelab";
    image = "twingate/connector:1.87.0@sha256:b348b79b6193062a40b8b6131beda8b2f42e64753e34a5908d93fc73acaeb503";
  };
}