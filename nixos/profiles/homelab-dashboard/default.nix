{ config, ... }:

{
  imports = [
    ../../modules/oci-containers/homelab-dashboard
  ];

  sops.secrets.dashboard_env = {
    sopsFile = ./dashboard.env;
    format = "dotenv";
    key = "";
  };

  services.homelab.dashboard = {
    enable = true;
    environmentFile = config.sops.secrets.dashboard_env.path;
    image = "allanelewis/homelab-dashboard:v2026.07.0@sha256:2ba75d2d60d1388a8765669f7d4931d89adc0108db2f6b96d6dff100885cfff6";
  };
}
