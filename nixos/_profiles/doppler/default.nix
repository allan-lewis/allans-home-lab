{ dopplerConfig, dopplerProject, dopplerTokenKey, ... }:

{
  imports = [
    ../../_modules/doppler
  ];

  sops.secrets.doppler_token = {
    sopsFile = ./doppler.yaml;
    key = dopplerTokenKey;
    path = "/var/lib/homelab-secrets/doppler/doppler_token";
    owner = "lab";
    group = "lab";
    mode = "0600";
  };

  services.homelab.doppler = {
    enable = true;

    user = "lab";
    scopeDir = "/home/lab";

    tokenFile = "/var/lib/homelab-secrets/doppler/doppler_token";

    project = dopplerProject;
    dopplerConfig = dopplerConfig;
  };
}
