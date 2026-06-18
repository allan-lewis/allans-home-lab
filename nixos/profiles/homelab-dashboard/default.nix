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
    image = "allanelewis/homelab-dashboard:v2026.06.1@sha256:a272f571d575ca672c51d8e6f7053f85443a3ff74ee9a011b3f358a1d3b82321";
  };
}
