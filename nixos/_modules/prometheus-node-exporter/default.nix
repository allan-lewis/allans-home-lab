{ ... }:

{
  #: setup textfile collector directory
  systemd.tmpfiles.rules = [
    "d /var/lib/node_exporter/textfile_collector 0755 root root -"
  ];

  #: configure and run the service
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
}