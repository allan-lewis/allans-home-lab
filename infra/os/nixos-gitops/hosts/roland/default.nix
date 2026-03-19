{ config, pkgs, lib, ... }:

let
  cfg = config.homelab.bareMetal;
in
{
  imports = [
    ../../profiles/bare-metal
    ../../profiles/base
    ../../profiles/desktop
  ];

  networking.hostName = "roland";

  homelab.bareMetal = {
    interface = "enp4s0";
    address = "192.168.86.206";
    prefixLength = 24;
  };

  # ---- USER ----
  users.users.lab = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" ];
  };

  home-manager.users.lab = { ... }: {
    xdg.configFile."hypr/hyprland.conf".source =
      ../../assets/hyprland.conf;

    xdg.configFile."ghostty/config".source =
      ../../assets/ghostty/config.ghostty;

    home.file."wallpapers/default.png".source =
      ../../assets/wallpaper/nix-wallpaper-binary-blue.png;

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = /home/lab/wallpapers/default.png
      wallpaper = ,/home/lab/wallpapers/default.png
    '';
  };

  # ---- HYPRLAND ----
  programs.hyprland.enable = true;

  # Wayland + portals
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-gtk
  ];

  # ---- GREETD LOGIN MANAGER ----
systemd.defaultUnit = "graphical.target";

services.greetd = {
  enable = true;
  settings = {
    default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --cmd Hyprland";
      user = "greeter";
    };
  };
};

systemd.services."getty@tty1".enable = false;
systemd.services."autovt@tty1".enable = false;

  # ---- AUDIO ----
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  security.rtkit.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # ---- OPENSSH ----
  services.openssh.enable = true;

  services.homelab.managedState.enable = lib.mkForce false;

  system.stateVersion = "25.11";
}
