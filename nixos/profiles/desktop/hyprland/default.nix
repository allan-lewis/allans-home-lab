{ pkgs, ... }:

{
  imports = [
    ./wlogout
  ];

  #: enable hyrpland
  programs.hyprland.enable = true;

  home-manager.users.lab = { ... }: {
    #: set the current desktop environment to hyprland
    home.sessionVariables = {
      XDG_CURRENT_DESKTOP = "Hyprland";
    };

    #: install hyprland-specific packages
    home.packages = with pkgs; [
      wev
    ];

    #: register default applications by type
    xdg.mimeApps.defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "text/plain" = [ "codium.desktop" ];
      "x-scheme-handler/http" = [ "google-chrome.desktop" ];
      "x-scheme-handler/https" = [ "google-chrome.desktop" ];
    };

    #: configure hyprland
    xdg.configFile."hypr/hyprland.conf".source =
      ./dotfiles/hypr/hyprland.conf;

    #: configure wallpaper
    home.file."wallpapers/default.png".source =
      ./dotfiles/wallpaper/nix-wallpaper-binary-blue.png;

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = /home/lab/wallpapers/default.png
      wallpaper = ,/home/lab/wallpapers/default.png
    '';

    #: configure idle and lock screens
    xdg.configFile."hypr/hypridle.conf".source =
      ./dotfiles/hypr/hypridle.conf;

    xdg.configFile."hypr/hyprlock.conf".source =
      ./dotfiles/hypr/hyprlock.conf;

    #: enable and configure waybar
    programs.waybar = {
      enable = true;

      settings = import ./waybar-settings.nix { inherit pkgs; };

      style = builtins.readFile ./dotfiles/waybar/style.css;
    };
  };
}