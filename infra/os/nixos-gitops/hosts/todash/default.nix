{ config, pkgs, lib, ... }:

let
  featureFlagBackup = false;
  featureFlagDevOps = true;
  featureFlagNodeExporter = true;
  featureFlagRestore = false;
  featureFlagPostgresDump = false;
  featureFlagS3Mirror = false;
  featureFlagTailscale = false;
in
{
  imports = [
    ./packages.nix
    ./tmpfiles.nix
    ./secrets.nix
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.lab = { pkgs, ... }: {
    home.stateVersion = "25.11";

    xdg.configFile."zsh/zshrc.local".source = ./assets/zshrc.local;

    programs.git = {
      enable = true;
      userName  = "Allan Lewis";
      userEmail = "allan.e.lewis@gmail.com";
    };

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

  environment.systemPackages = with pkgs; [
    awscli2
    btop
    clang
    cmatrix
    curl
    doppler
    gcc
    ghostty.terminfo
    git
    gnumake
    jq
    just
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
    enable = true;

    user = "lab";
    scopeDir = "/home/lab/src";

    tokenFile = "/var/lib/homelab-secrets/doppler/doppler_token";

    project = "orchestrator";
    dopplerConfig = "mat";
  };

  services.tailscale = lib.mkIf featureFlagTailscale {
    enable = true;
    authKeyFile = "/run/secrets/tailscale-authkey";
    extraUpFlags = [
      "--accept-dns=true"
    ];
  };

  networking.firewall.trustedInterfaces =
    lib.mkIf config.services.tailscale.enable [ "tailscale0" ];

  system.stateVersion = "25.11";
}