{ config, lib, ... }:

let
  cfg = config.services.homelab.twingateConnector;
in
{
  options.services.homelab.twingateConnector = {
    enable = lib.mkEnableOption "Twingate connector";

    connectorKey = lib.mkOption {
      type = lib.types.str;
      example = "modestAnteater";
      description = "Key under twingate.connectors in secrets/twingate.yaml";
    };

    networkName = lib.mkOption {
      type = lib.types.str;
      description = "Twingate network name";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "twingate/connector:1.85.0@sha256:21d71de5d6605936e23b1d15f268b1d94b68de685f7b51603b99e17c180002cb";
      description = "Twingate connector image";
    };

    sopsFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../secrets/twingate.yaml;
      description = "SOPS file containing connector credentials";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.twingate_access_token = {
      sopsFile = cfg.sopsFile;
      key = "twingate/connectors/${cfg.connectorKey}/access_token";
    };

    sops.secrets.twingate_refresh_token = {
      sopsFile = cfg.sopsFile;
      key = "twingate/connectors/${cfg.connectorKey}/refresh_token";
    };

    sops.templates."twingate-connector.env" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        TWINGATE_NETWORK=${cfg.networkName}
        TWINGATE_ACCESS_TOKEN=${config.sops.placeholder.twingate_access_token}
        TWINGATE_REFRESH_TOKEN=${config.sops.placeholder.twingate_refresh_token}
      '';
    };

    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers.twingate-connector = {
      image = cfg.image;
      environmentFiles = [
        config.sops.templates."twingate-connector.env".path
      ];
    };
  };
}