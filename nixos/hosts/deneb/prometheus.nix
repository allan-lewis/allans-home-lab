{ config, ... }:

{
  services.homelab.prometheus.scrapeConfigs = [
    {
      job_name = "gatus";
      static_configs = [
        {
          #: deneb has no ip.allanshomelab.com DNS entry yet, so scrape via its static address
          targets = [ "192.168.10.108:8080" ];
          labels.__meta_friendly_instance = "deneb";
        }
      ];
      relabel_configs = config.homelab.prometheus.friendlyRelabelConfigs;
    }
  ];
}
