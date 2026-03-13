{
  description = "Allan's Homelab - GitOps experiment for todash";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.todash = nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        home-manager.nixosModules.home-manager

        ./hardware-configuration.nix
        ./modules/backup-runner.nix
        ./modules/dev-checkouts.nix
        ./modules/doppler.nix
        ./modules/homelab-hello.nix
        ./modules/homelab-tasks.nix
        ./modules/managed-directories.nix
        ./modules/postgres-db-backup.nix
        ./modules/s3-local-mirror.nix

        ({ config, pkgs, lib, ... }: 
        let
          featureFlagBackup = false;
          featureFlagDevOps = false;
          featureFlagNodeExporter = true;
          featureFlagRestore = false;
          featureFlagPostgresDump = false;
          featureFlagS3Mirror = false;
          featureFlagTailscale = false;
        in
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.lab = { pkgs, ... }: {
            home.stateVersion = "25.11";

            xdg.configFile."zsh/zshrc.local".source = ./assets/zshrc.local;

            programs.zsh = {
              enable = true;
              autosuggestion.enable = true;
              syntaxHighlighting.enable = true;
              initContent = ''
                source ~/.config/zsh/zshrc.local
              '';
            };

            programs.starship = {
              enable = true;
            };

            programs.tmux = {
              enable = true;
              extraConfig = builtins.readFile ./assets/tmux.conf;
            };

            xdg.configFile."starship.toml".source = ./assets/starship.toml;

            xdg.configFile."nvim" = {
              source = ./assets/nvim;
              recursive = true;
            };

            home.packages = with pkgs; [
              fastfetch
              fd
              fzf
              neovim
              ripgrep
              starship
              tmux
            ];
          };

          programs.zsh.enable = true;

          boot.loader.grub.enable = true;
          boot.loader.grub.device = "/dev/sda";

          networking.hostName = "todash";

          virtualisation.docker.enable = true;

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

          users.groups.lab = {};
          users.groups.aws = {};

          users.users.lab = {
            isNormalUser = true;
            group = "lab";
            extraGroups = [ "wheel" "aws" "docker" ];
            shell = pkgs.zsh;
            hashedPassword = "!";
          };

          security.sudo.enable = true;
          security.sudo.wheelNeedsPassword = false;

          time.timeZone = "UTC";

          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          nixpkgs.config.allowUnfree = true;

          environment.etc."tmux.conf".text = lib.mkForce "";

          systemd.tmpfiles.rules = [
            "d /home/lab/.ssh 0700 lab lab -"
            "d /home/lab/.config 0755 lab lab -"
            "d /home/lab/.config/zsh 0755 lab lab -"
            "d /root/.ssh 0700 root root -"
            "d /var/lib/node_exporter/textfile_collector 0755 root root -"
            "d /opt/docker-compose 0750 root root -"
            "d /home/lab/managed-dir-0 0755 lab lab -"
            "d /home/lab/managed-dir-1 0755 root root -"
            "d /var/lib/homelab-secrets/doppler 0700 root root -"
            "d /var/lib/postgres-db-dumps 0755 root root -"
            "d /var/lib/tailscale 0700 root root -"
            "d /etc/allans-home-lab/managed-directories 0755 root root -"
            "d /var/lib/homelab-secrets 0711 root root -"
            "d /var/lib/homelab-secrets/ssh 0711 root root -"
            "d /var/lib/homelab-secrets/ssh/root 0700 root root -"
            "f /var/lib/homelab-secrets/ssh/root/id_ed25519 0600 root root -"
            "f /var/lib/homelab-secrets/ssh/root/id_ed25519.pub 0644 root root -"
            "d /etc/allans-home-lab/secrets 0700 root root -"
            "L+ /root/.ssh/id_ed25519 - - - - /var/lib/homelab-secrets/ssh/root/id_ed25519"
            "L+ /root/.ssh/id_ed25519.pub - - - - /var/lib/homelab-secrets/ssh/root/id_ed25519.pub"
          ];

          environment.systemPackages = with pkgs; [
            btop
            clang
            cmatrix
            curl
            gcc
            ghostty.terminfo
            git
            gnumake
            jq
            net-tools
            python3
            trash-cli
            tree
            tree-sitter
            unzip
          ];

          services.homelab.hello = {
            enable = true;
            intervalSeconds = 15;
          };

          services.prometheus.exporters.node = lib.mkIf featureFlagNodeExporter {
            enable = true;
            listenAddress = "0.0.0.0";
            port = 9100;
            openFirewall = true;
            enabledCollectors = [ "textfile" ];
            extraFlags = [
              "--collector.textfile.directory=/var/lib/node_exporter/textfile_collector"
            ];
          };

          services.homelab.managedDirectories = lib.mkIf featureFlagRestore {
            enable = false;
            writablePaths = [
              "/home/lab/managed-dir-0"
              "/home/lab/managed-dir-1"
            ];
          };

          services.homelab.backupRunner = lib.mkIf featureFlagBackup {
            enable = false;
            schedule = "*-*-* *:30:00";

            rsyncFlags =
              lib.splitString " "
                "-aHAX --numeric-ids --delete-delay --partial --partial-dir=.rsync-partial --human-readable --sparse --mkpath";

            readablePaths = [
              "/home/lab/managed-dir-0"
              "/home/lab/managed-dir-1"
            ];
          };

          services.homelab.devCheckouts = lib.mkIf featureFlagDevOps {
            enable = false;

            schedule = "hourly";

            rootDir = "/home/lab/src";

            user = "lab";

            repos = [ ];
          };

          services.homelab.s3LocalMirror = lib.mkIf featureFlagS3Mirror {
            enable = false;

            schedule = "Sat *-*-* 07:00:00";

            syncFlags = "--delete --only-show-errors";

            buckets = [ ];
          };

          services.homelab.postgresDbBackup = lib.mkIf featureFlagPostgresDump {
            enable = false;
            schedule = "*-*-* 05:00:00";

            db = "";
            user = "";
            container = "";
            extraArgs = "";

            backupDir = "/var/lib/postgres-db-dumps";
            passwordFile = "/etc/allans-home-lab/secrets/postgres_dump_pass";
          };

          services.homelab.doppler = lib.mkIf featureFlagDevOps {
            enable = false;

            user = "lab";
            scopeDir = "/home/lab/src";

            tokenFile = "/var/lib/homelab-secrets/doppler/doppler_token";

            project = "";
            dopplerConfig = "";
          };

          services.tailscale = lib.mkIf featureFlagTailscale {
            enable = false;
            authKeyFile = "/run/secrets/tailscale-authkey";
            extraUpFlags = [
              "--accept-dns=true"
            ];
          };

          networking.firewall.trustedInterfaces = lib.mkIf config.services.tailscale.enable [ "tailscale0" ];

          system.stateVersion = "25.11";
        })
      ];
    };
  };
}