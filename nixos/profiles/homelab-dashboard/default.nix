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
    image = "allanelewis/homelab-dashboard:v2026.06.6@sha256:e0575c153947e92f85e2c5b57e9efef9410dc0ecef93c27643091ad1d29e4ac7";
  };
}
