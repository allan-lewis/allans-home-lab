{ pkgs, ... }:

{
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
    slurp
    waybar
    wl-clipboard
    wofi
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.thunar-volman
  ];

}
