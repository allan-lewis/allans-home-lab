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
    image = "allanelewis/homelab-dashboard:v2026.06.3@sha256:60a828f337530cfd3d51def2f6a3e93ccecadb27f7f1ca94b1eb3468250a6bd2";
  };
}
