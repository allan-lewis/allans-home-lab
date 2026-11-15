{ config, ... }:

let
  friendlyRelabelConfigs = config.homelab.prometheus.friendlyRelabelConfigs;
in
{
  services.homelab.prometheus.scrapeConfigs = [
    {
      job_name = "node-exporter";
      static_configs = [
        {
          targets = [ "rigel.ts.allanshomelab.com:9100" ];
          labels.__meta_friendly_instance = "rigel";
        }
        {
          targets = [ "castor.ip.allanshomelab.com:9100" ];
          labels.__meta_friendly_instance = "castor";
        }
        {
          targets = [ "bellatrix.ip.allanshomelab.com:9100" ];
          labels.__meta_friendly_instance = "bellatrix";
        }
        {
          targets = [ "polaris.ip.allanshomelab.com:9100" ];
          labels.__meta_friendly_instance = "polaris";
        }
        {
          targets = [ "pollux.ip.allanshomelab.com:9100" ];
          labels.__meta_friendly_instance = "pollux";
        }
        {
          targets = [ "capella.ip.allanshomelab.com:9100" ];
          labels.__meta_friendly_instance = "capella";
        }
        {
          targets = [ "regulus.ip.allanshomelab.com:9100" ];
          labels.__meta_friendly_instance = "regulus";
        }
        {
          targets = [ "sirius.ip.allanshomelab.com:9100" ];
          labels.__meta_friendly_instance = "sirius";
        }
        {
          targets = [ "canopus.ip.allanshomelab.com:9100" ];
          labels.__meta_friendly_instance = "canopus";
        }
        {
          targets = [ "procyon.ip.allanshomelab.com:9100" ];
          labels.__meta_friendly_instance = "procyon";
        }
        {
          targets = [ "arcturus.ip.allanshomelab.com:9100" ];
          labels.__meta_friendly_instance = "arcturus";
        }
        {
          targets = [ "antares.ip.allanshomelab.com:9100" ];
          labels.__meta_friendly_instance = "antares";
        }
      ];
      relabel_configs = friendlyRelabelConfigs;
    }

    {
      job_name = "cloudflare";
      static_configs = [
        {
          targets = [ "castor.ip.allanshomelab.com:2000" ];
          labels.__meta_friendly_instance = "castor";
        }
      ];
      relabel_configs = friendlyRelabelConfigs;
    }

    {
      job_name = "todo";
      static_configs = [
        {
          targets = [ "192.168.86.212:9100" ];
          labels.__meta_friendly_instance = "christine";
        }
        {
          targets = [ "192.168.86.211:9100" ];
          labels.__meta_friendly_instance = "gan";
        }
      ];
      relabel_configs = friendlyRelabelConfigs;
    }

    {
      job_name = "gatus";
      static_configs = [
        {
          targets = [ "castor.ip.allanshomelab.com:8080" ];
          labels.__meta_friendly_instance = "castor";
        }
      ];
      relabel_configs = friendlyRelabelConfigs;
    }

    {
      job_name = "homelab-metrics";
      static_configs = [
        {
          targets = [ "bellatrix.ip.allanshomelab.com:9102" ];
          labels.__meta_friendly_instance = "bellatrix";
        }
        {
          targets = [ "castor.ip.allanshomelab.com:9102" ];
          labels.__meta_friendly_instance = "castor";
        }
        {
          targets = [ "pollux.ip.allanshomelab.com:9102" ];
          labels.__meta_friendly_instance = "pollux";
        }
        {
          targets = [ "capella.ip.allanshomelab.com:9102" ];
          labels.__meta_friendly_instance = "capella";
        }
        {
          targets = [ "regulus.ip.allanshomelab.com:9102" ];
          labels.__meta_friendly_instance = "regulus";
        }
        {
          targets = [ "antares.ip.allanshomelab.com:9102" ];
          labels.__meta_friendly_instance = "antares";
        }
      ];
      relabel_configs = friendlyRelabelConfigs;
    }
  ];
}
