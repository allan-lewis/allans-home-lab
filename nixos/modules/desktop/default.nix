{ pkgs, ... }:

{
  imports = [
    ./hyprland.nix
    ./wlogout.nix
  ];

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    EDITOR = "nvim";
    TERMINAL = "ghostty";
  };

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

  users.users.lab = {
    extraGroups = [ "wheel" "video" "audio" ];
  };

  security.rtkit.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  systemd.defaultUnit = "graphical.target";

services.greetd = {
  enable = true;
  settings = {
    default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --user-menu --cmd Hyprland";
      user = "greeter";
    };
  };
};

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
}