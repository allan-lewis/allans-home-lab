{ hostName, nixosVersion, lib, ... }:

{
  imports = [
    ./gatus.nix
    ./prometheus.nix

    ../../modules/virtual-machine

    ../../profiles/prometheus-stack
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  #: deneb only needs short-lived retention, not the 14d default
  services.homelab.prometheus.retentionTime = "8d";

  #: deneb runs prometheus only, not the full stack
  services.homelab.grafana.enable = lib.mkForce false;
  services.homelab.alertmanager.enable = lib.mkForce false;
}
