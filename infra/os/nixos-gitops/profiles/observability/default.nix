{ lib, pkgs, ... }:

{
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

  systemd.tmpfiles.rules = [
    "d /var/lib/node_exporter/textfile_collector 0755 root root -"
  ];

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9100;
    openFirewall = true;
    enabledCollectors = [ "textfile" ];
    extraFlags = [
      "--collector.textfile.directory=/var/lib/node_exporter/textfile_collector"
    ];
  };

  services.homelab.metrics = {
    enable = true;
    port = 9102;
    image = "docker.io/allanelewis/homelab-metrics@sha256:0ec3727dece3b49e0cb2cddc39650670c87b3bf4bb9c1024244ac5329ad5719f";
  };

}