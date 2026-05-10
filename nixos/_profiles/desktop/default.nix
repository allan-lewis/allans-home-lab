{ config, lib, pkgs, ... }:

{
  # imports = [
  #   ./hyprland.nix
  #   ./wlogout.nix
  # ];

  #: set environment variables for desktop
  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    EDITOR = "nvim";
    TERMINAL = "ghostty";
  };

  #: setup the lab user with a password
  users.mutableUsers = false;

  sops.secrets.lab_password = {
    sopsFile = ./passwords.yaml;
  };

  users.users.lab = {
    extraGroups = [ "wheel" "video" "audio" ];

    initialPassword = lib.mkForce null;
    initialHashedPassword = lib.mkForce null;
    password = lib.mkForce null;
    hashedPassword = lib.mkForce null;
    hashedPasswordFile = lib.mkForce config.sops.secrets.lab_password.path;
  };

  #: install desktop packages
  environment.systemPackages = with pkgs; [
    bibata-cursors
    file-roller
    ghostty
    google-chrome
    grim
    hypridle
    hyprlock
    hyprpaper
    imv
    mako
    pavucontrol
    slurp
    waybar
    wl-clipboard
    wofi
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.thunar-volman
  ];

  #: install fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  #: enable bluetooth support
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  #: audio support/setup 
  security.rtkit.enable = true;
  
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  #: login to a graphical target by default
  systemd.defaultUnit = "graphical.target";

  #: use greetd and tuigreet for a lightweight login prompt
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --user-menu --cmd Hyprland";
        user = "greeter";
      };
    };
  };
}
