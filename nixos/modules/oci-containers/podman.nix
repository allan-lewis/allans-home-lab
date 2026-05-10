{ config, lib, pkgs, ... }:

let
  cfg = config.services.homelab.containers;
in
{
  options.services.homelab.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {
        image = lib.mkOption {
          type = lib.types.str;
        };

        port = lib.mkOption {
          type = lib.types.port;
        };

        internalPort = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = null;
        };

        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {};
        };

        volumes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };
      };
    }));
    default = {};
  };

  config = {
    virtualisation.podman.enable = true;

    systemd.services.force-ipv4-forwarding = {
      description = "Force IPv4 forwarding on after networking settles";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "NetworkManager.service"
        "systemd-networkd.service"
      ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.procps}/bin/sysctl -w net.ipv4.ip_forward=1
      '';
    };

    virtualisation.oci-containers = {
      backend = "podman";

      containers =
        lib.mapAttrs (_: c: {
          image = c.image;
          autoStart = true;

          ports = [
            "${toString c.port}:${toString (
              if c.internalPort != null then c.internalPort else c.port
            )}/tcp"
          ];

          environment = c.environment;
          volumes = c.volumes;

          extraOptions = [ "--replace" ];
        }) cfg;
    };

    networking.firewall.allowedTCPPorts =
      lib.mapAttrsToList (_: c: c.port) cfg;
  };
}