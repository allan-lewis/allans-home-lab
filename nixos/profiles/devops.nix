{ ... }:

{
  imports = [
    ../modules/aws/lab.nix
    ../modules/devops.nix
    ../modules/doppler.nix
    ../modules/lab-keys.nix
  ];

  services.homelab.doppler = {
    enable = true;

    user = "lab";
    scopeDir = "/home/lab/src";

    tokenFile = "/var/lib/homelab-secrets/doppler/doppler_token";

    project = "orchestrator";
    dopplerConfig = "mat";
  };
}