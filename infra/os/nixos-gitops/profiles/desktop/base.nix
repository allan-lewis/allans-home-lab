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
    ghostty
    google-chrome
    hypridle
    hyprlock
    hyprpaper
    mako
    waybar
    wl-clipboard
    wofi
  ];

}
