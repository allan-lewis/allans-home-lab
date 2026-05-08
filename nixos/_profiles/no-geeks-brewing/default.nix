{ config, ... }:

{
  imports = [
    ../../_modules/oci-containers/no-geeks-brewing
  ];

  sops.secrets.ngb_env = {
    sopsFile = ./no-geeks-brewing.env;
    format = "dotenv";
    key = "";
  };

  services.homelab.noGeeksBrewing = {
    enable = true;
    environmentFile = config.sops.secrets.ngb_env.path;
  };
}