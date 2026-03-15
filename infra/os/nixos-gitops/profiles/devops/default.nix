{ pkgs, ... }:

{
  imports = [
    ./secrets.nix
    ./tmpfiles.nix
  ];

  environment.systemPackages = with pkgs; [
    awscli2
    clang
    doppler
    gcc
    git
    gnumake
    just
  ];

  services.homelab.devCheckouts = {
    enable = true;

    schedule = "hourly";

    rootDir = "/home/lab/src";

    user = "lab";

    repos = [
      {
        repo = "git@github.com:allan-lewis/allans-home-lab.git";
        dest = "allans-home-lab";
        version = "main";
      }
    ];
  };

  services.homelab.doppler = {
    enable = true;

    user = "lab";
    scopeDir = "/home/lab/src";

    tokenFile = "/var/lib/homelab-secrets/doppler/doppler_token";

    project = "orchestrator";
    dopplerConfig = "mat";
  };
}