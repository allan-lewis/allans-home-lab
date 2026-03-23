{ ... }:

{
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

  services.homelab.containers.homelab-metrics = {
    port = 9102;
    image = "docker.io/allanelewis/homelab-metrics@sha256:0ec3727dece3b49e0cb2cddc39650670c87b3bf4bb9c1024244ac5329ad5719f";
  };

}