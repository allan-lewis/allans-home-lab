{ config, lib, pkgs, ... }:
let 
  activeTheme = config.homelab.desktop.themes.gruvbox-dark;
  # activeTheme = config.homelab.desktop.themes.nix-blue;

  starshipToml = builtins.readFile ../../../../dotfiles/starship/starship.toml;

  renderedStarshipToml = builtins.replaceStrings
    [ ''palette = "gruvbox_dark_hard"'' ]
    [ ''palette = "${activeTheme.starshipPalette}"'' ]
    starshipToml;
in
{
  imports = [
    ./themes
    ./wlogout
  ];

  homelab.desktop.wlogout.colors = activeTheme.colors;

  #: enable hyrpland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true; 
  };

  home-manager.users.lab = { config, ... }: {
    #: customize starship palette
    xdg.configFile."starship.toml" = lib.mkForce {
      text = renderedStarshipToml;
    };

    #: export home-manager session variables for uwsm
    xdg.configFile."uwsm/env".source =
      "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

    #: install hyprland-specific packages
    home.packages = with pkgs; [
      wev
      hyprpaper
    ];

    #: register default applications by type
    xdg.mimeApps.defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "text/plain" = [ "codium.desktop" ];
      "x-scheme-handler/http" = [ "google-chrome.desktop" ];
      "x-scheme-handler/https" = [ "google-chrome.desktop" ];
    };

    #: configure hyprland
    xdg.configFile."hypr/hyprland.conf".text =
      builtins.replaceStrings
        [ "\${pkgs.polkit_gnome}" ]
        [ "${pkgs.polkit_gnome}" ]
        (builtins.readFile ./dotfiles/hypr/hyprland.conf);

    #: configure wallpaper
    home.file."wallpapers/default.png".source = activeTheme.wallpaper;

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      splash = false
      
      wallpaper {
          monitor =
          path = /home/lab/wallpapers/default.png
          fit_mode = cover
      }
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