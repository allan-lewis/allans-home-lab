{ config, ... }:

{
  services.homelab.prometheus.scrapeConfigs = [
    {
      job_name = "gatus";
      static_configs = [
        {
          targets = [ "castor.ip.allanshomelab.com:8080" ];
          labels.__meta_friendly_instance = "castor";
        }
      ];
      relabel_configs = config.homelab.prometheus.friendlyRelabelConfigs;
    }
  ];
}
