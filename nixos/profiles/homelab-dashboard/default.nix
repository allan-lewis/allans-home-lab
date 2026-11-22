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
    image = "allanelewis/homelab-dashboard:v2026.11.1@sha256:9957da914580e6ed326e78eab06e95f0017b9862fe4947e45793e028be2be141";
  };
}
