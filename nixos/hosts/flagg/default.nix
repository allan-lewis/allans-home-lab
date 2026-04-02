{ lib, ... }:

let
  hostName = "flagg";
in
{
  imports = [
    ../../profiles/alertmanager
    ../../profiles/authentik
    ../../profiles/bare-metal
    ../../profiles/base
    ../../profiles/cloudflare
    ../../profiles/containers/twingate
    ../../profiles/gatus
    ../../profiles/grafana
    ../../profiles/prometheus
    ../../profiles/tailscale
    ../../profiles/traefik
  ];

  networking.hostName = hostName;

  homelab.bareMetal.interface = "eth1";
  homelab.bareMetal.address = "192.168.86.204";

  services.homelab.managedState.enable = lib.mkForce false;

  services.homelab.twingateConnector = {
    enable = true;
    connectorKey = "modestAnteater";
    networkName = "allanshomelab";
    image = "twingate/connector:1.85.0@sha256:5e126d3ce36aa20b8977bab0b7e3da90ba1e10476234020a81cbdaf02781136b";
  };

  services.homelab.cloudflaredTunnel = {
    enable = true;
  };

  services.homelab.authentikCompose = {
    enable = true;
    version = "2025.10.3";
    httpPort = 9180;
    httpsPort = 9143;
  };

  services.homelab.prometheus = {
    enable = true;
  };

  services.homelab.alertmanager = {
    enable = true;
  };

  services.homelab.grafana = {
    enable = true;
    port = 3071;
    domain = "grafana.allanshomelab.com";
  };

  system.stateVersion = "25.11";
}