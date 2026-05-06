{ dopplerConfig, dopplerProject, dopplerTokenKey, pkgs, ... }:

{
  imports = [
    ../../_modules/aws
    ../../_modules/doppler
  ];

  #: enable docker and add lab to group
  virtualisation.docker.enable = true;
  users.users.lab.extraGroups = [ "docker" ];

  #: enable aws for the lab user
  homelab.awsCredentialsForLabUser = true;

  #: install system packages
  environment.systemPackages = with pkgs; [
    ansible
    clang
    gnumake
    just
    packer
    terraform
    uv
  ];

  #: ensure that source code is up-to-date every hour
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
      {
        repo = "git@github.com:allan-lewis/dotfiles.git";
        dest = "dotfiles";
        version = "main";
      }
      {
        repo = "git@github.com:allan-lewis/homelab-metrics.git";
        dest = "homelab-metrics";
        version = "main";
      }
      {
        repo = "git@github.com:allan-lewis/no-geeks-brewing-go.git";
        dest = "no-geeks-brewing-go";
        version = "main";
      }
    ];
  };

  #: ensure that source code is checked out after any switch
  system.activationScripts.devCheckoutsAfterSwitch = {
    deps = [ "etc" ];
    text = ''
      mkdir -p /run/nixos
      if ! grep -qxF 'homelab-task-dev_checkouts_sync.service' /run/nixos/activation-restart-list 2>/dev/null; then
        printf '%s\n' 'homelab-task-dev_checkouts_sync.service' >> /run/nixos/activation-restart-list
      fi
    '';
  };

  #: setup the lab user to be able to commit to github
  home-manager.users.lab = { ... }: {
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "Allan Lewis";
          email = "allan.e.lewis@gmail.com";
        };
      };
    };
  };

  #: configure and enable doppler
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
