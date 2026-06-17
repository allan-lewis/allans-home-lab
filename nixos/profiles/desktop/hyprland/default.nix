{ config, lib, pkgs, ... }:
let 
  activeTheme = config.homelab.desktop.themes.gruvbox-dark;
  # activeTheme = config.homelab.desktop.themes.nix-blue;

  starshipToml = builtins.readFile ../../../../dotfiles/starship/starship.toml;

  renderedStarshipToml = builtins.replaceStrings
    [ ''palette = "gruvbox_dark_hard"'' ]
    [ ''palette = "${activeTheme.starshipPalette}"'' ]
    starshipToml;

  hyprlockConf = builtins.readFile ./dotfiles/hypr/hyprlock.conf;

  renderedHyprlockConf = builtins.replaceStrings
    [
      "@LOCK_TIME@"
      "@LOCK_INPUT_TEXT@"
      "@LOCK_INPUT_INNER@"
      "@LOCK_INPUT_OUTER@"
      "@LOCK_INPUT_CHECK@"
      "@LOCK_INPUT_FAIL@"
    ]
    [
      activeTheme.colors.lockTime
      activeTheme.colors.lockInputText
      activeTheme.colors.lockInputInner
      activeTheme.colors.lockInputOuter
      activeTheme.colors.lockInputCheck
      activeTheme.colors.lockInputFail
    ]
    hyprlockConf;

  waybarCss = builtins.readFile ./dotfiles/waybar/style.css;

  renderedWaybarCss = builtins.replaceStrings
    [
      "@WAYBAR_TEXT@"
      "@WAYBAR_BACKGROUND@"
      "@WAYBAR_IDENTITY@"
      "@WAYBAR_POWER@"
      "@WAYBAR_CLOCK@"
      "@WAYBAR_NETWORK@"
      "@WAYBAR_STATS@"
    ]
    [
      activeTheme.colors.waybarText
      activeTheme.colors.waybarBackground
      activeTheme.colors.waybarIdentity
      activeTheme.colors.waybarPower
      activeTheme.colors.waybarClock
      activeTheme.colors.waybarNetwork
      activeTheme.colors.waybarStats
    ]
    waybarCss;
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

    xdg.configFile."hypr/hyprlock.conf".text =
      renderedHyprlockConf;

    #: enable and configure waybar
    programs.waybar = {
      enable = true;

      settings = import ./waybar-settings.nix { inherit pkgs; };

      style = renderedWaybarCss;
    };
  };
}