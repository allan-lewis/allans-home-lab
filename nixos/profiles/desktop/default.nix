{ config, lib, pkgs, ... }:

{
  imports = [
    ./default-user
    ./hyprland
  ];

  #: set environment variables for desktop
  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    EDITOR = "nvim";
    TERMINAL = "ghostty";
  };

  #: enable the xdg desktop portal framework
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];

    config.common.default = [ "gtk" ];
  };

  #: enable policy kit
  security.polkit.enable = true;

  #: add the lab user to the audio and video groups
  users.users.lab = {
    extraGroups = [ "video" "audio" ];
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
    thunar
    thunar-archive-plugin
    thunar-volman
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

  #: discourage default login prompts
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  #: automatically log in the lab user (hyprland will lock the screen)
  services.greetd = {
    enable = true;

    settings = {
      initial_session = {
        command = "${pkgs.uwsm}/bin/uwsm start -eD Hyprland hyprland.desktop";
        user = "lab";
      };

      default_session = {
        command = "${pkgs.uwsm}/bin/uwsm start -eD Hyprland hyprland.desktop";
        user = "lab";
      };
    };
  };
}
