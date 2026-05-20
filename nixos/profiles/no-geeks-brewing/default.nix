{ config, ... }:

{
  imports = [
    ../../modules/oci-containers/no-geeks-brewing
  ];

  sops.secrets.ngb_env = {
    sopsFile = ./no-geeks-brewing.env;
    format = "dotenv";
    key = "";
  };

  services.homelab.noGeeksBrewing = {
    enable = true;
    environmentFile = config.sops.secrets.ngb_env.path;
    image = "allanelewis/ngb-go:v2026.04.0@sha256:32261fc7b13d58ccb6bf8f43ea7e07bd60a9213598a05d0ea462fc223bb83ec2";
  };
}