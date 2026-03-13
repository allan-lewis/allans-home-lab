{
  description = "Allan's Homelab - GitOps experiment for todash";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.todash = nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        ./hardware-configuration.nix
        ./modules/homelab-hello.nix
        ./modules/homelab-tasks.nix

        ({ pkgs, lib, ... }: {
          boot.loader.grub.enable = true;
          boot.loader.grub.device = "/dev/sda";

          networking.hostName = "todash";

          services.openssh.enable = true;
          services.openssh.settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
          };
          services.openssh.extraConfig = ''
            AllowUsers lab
          '';

          services.qemuGuest.enable = true;
          services.cloud-init.enable = true;
          services.cloud-init.network.enable = true;

          networking.useNetworkd = true;
          networking.useDHCP = false;

          programs.zsh.enable = true;

          users.groups.lab = {};
          users.groups.aws = {};

          users.users.lab = {
            isNormalUser = true;
            group = "lab";
            extraGroups = [ "wheel" "aws" ];
            shell = pkgs.zsh;
            hashedPassword = "!";
          };

          security.sudo.enable = true;
          security.sudo.wheelNeedsPassword = false;

          time.timeZone = "UTC";

          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          nixpkgs.config.allowUnfree = true;

          environment.etc."tmux.conf".text = lib.mkForce "";

          system.activationScripts.labTmuxConf.text = ''
            install -D -m 0644 -o lab -g lab ${./assets/tmux.conf} /home/lab/.tmux.conf
          '';

          system.activationScripts.labStarshipConfig.text = ''
            install -D -m 0644 -o lab -g lab ${./assets/starship.toml} /home/lab/.config/starship.toml
          '';

          systemd.tmpfiles.rules = [
            "d /home/lab/.ssh 0700 lab lab -"
            "d /home/lab/.config 0755 lab lab -"
            "d /home/lab/.config/zsh 0755 lab lab -"
            "f /home/lab/.tmux.conf 0644 lab lab -"
            "d /root/.ssh 0700 root root -"
          ];

          environment.systemPackages = with pkgs; [
            btop
            clang
            cmatrix
            curl
            fd
            fzf
            gcc
            git
            gnumake
            jq
            neovim
            net-tools
            python3
            ripgrep
            starship
            tmux
            trash-cli
            tree
            tree-sitter
            unzip
            ghostty.terminfo
          ];

          services.homelab.hello = {
            enable = true;
            intervalSeconds = 15;
          };

          system.stateVersion = "25.11";
        })
      ];
    };
  };
}