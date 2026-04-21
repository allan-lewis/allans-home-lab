{ dopplerConfig, dopplerProject, dopplerTokenKey, ... }:
 
{
  imports = [
    ../modules/aws/lab.nix
    ../modules/devops.nix
    ../modules/doppler.nix
    ../modules/lab-keys.nix
  ];

  sops.secrets.doppler_token = {
    sopsFile = ../secrets/doppler.yaml;
    key = dopplerTokenKey;
    path = "/var/lib/homelab-secrets/doppler/doppler_token";
    owner = "lab";
    group = "lab";
    mode = "0600";
  };

  services.homelab.doppler = {
    enable = true;

    user = "lab";
    scopeDir = "/home/lab/src";

    tokenFile = "/var/lib/homelab-secrets/doppler/doppler_token";

    project = dopplerProject;
    dopplerConfig = dopplerConfig;
  };
}