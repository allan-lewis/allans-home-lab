{ config, lib, ... }:

let
  cfg = config.homelab.twingate;

  connectors = {
    modestAnteater = {
      networkName = "allanshomelab";
      image = "twingate/connector:1.89.0@sha256:303f4dfc3ee3af1fe4023a5eead95e8f903ae848ca55cc9a21132133ae081698";
    };

    valiantStingray = {
      networkName = "allanshomelab";
      image = "twingate/connector:1.89.0@sha256:303f4dfc3ee3af1fe4023a5eead95e8f903ae848ca55cc9a21132133ae081698";
    };
  };

  selectedConnector = connectors.${cfg.connectorName};
in
{
  imports = [
    ../../modules/oci-containers/twingate
  ];

  options.homelab.twingate = {
    enable = lib.mkEnableOption "Twingate connector profile";

    connectorName = lib.mkOption {
      type = lib.types.enum (builtins.attrNames connectors);
      description = "Twingate connector config to use.";
    };

    sopsFile = lib.mkOption {
      type = lib.types.path;
      default = ./twingate.yaml;
      description = "SOPS file containing Twingate connector credentials.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.twingate_access_token = {
      sopsFile = cfg.sopsFile;
      key = "twingate/connectors/${cfg.connectorName}/access_token";
    };

    sops.secrets.twingate_refresh_token = {
      sopsFile = cfg.sopsFile;
      key = "twingate/connectors/${cfg.connectorName}/refresh_token";
    };

    sops.templates."twingate-connector.env" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        TWINGATE_NETWORK=${selectedConnector.networkName}
        TWINGATE_ACCESS_TOKEN=${config.sops.placeholder.twingate_access_token}
        TWINGATE_REFRESH_TOKEN=${config.sops.placeholder.twingate_refresh_token}
      '';
    };

    services.homelab.twingateConnector = {
      enable = true;
      image = selectedConnector.image;
      environmentFile = config.sops.templates."twingate-connector.env".path;
    };
  };
}