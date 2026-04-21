{ pkgs, ... }:

{
  imports = [
    ./dev-checkouts.nix
  ];

  virtualisation.docker.enable = true;

  users.users.lab.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    ansible
    clang
    gnumake
    just
    packer
    terraform
    uv
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

  system.activationScripts.devCheckoutsAfterSwitch = {
    deps = [ "etc" ];
    text = ''
      mkdir -p /run/nixos
      if ! grep -qxF 'homelab-task-dev_checkouts_sync.service' /run/nixos/activation-restart-list 2>/dev/null; then
        printf '%s\n' 'homelab-task-dev_checkouts_sync.service' >> /run/nixos/activation-restart-list
      fi
    '';
  };

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
}