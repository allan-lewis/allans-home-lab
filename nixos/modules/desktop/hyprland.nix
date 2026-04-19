{ pkgs, ... }:

{
  programs.hyprland.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-gtk
  ];

  home-manager.users.lab = { ... }: {
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    home.packages = [
      pkgs.polkit_gnome
      pkgs.wlogout
    ];

    xdg.configFile."hypr/hyprland.conf".source =
      ./dotfiles/hypr/hyprland.conf;

    xdg.configFile."hypr/hypridle.conf".source =
      ./dotfiles/hypr/hypridle.conf;

    xdg.configFile."hypr/hyprlock.conf".source =
      ./dotfiles/hypr/hyprlock.conf;

    xdg.configFile."ghostty/config".source =
      ./dotfiles/ghostty/config.ghostty;

    home.file."wallpapers/default.png".source =
      ./dotfiles/wallpaper/nix-wallpaper-binary-blue.png;

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = /home/lab/wallpapers/default.png
      wallpaper = ,/home/lab/wallpapers/default.png
    '';

    xdg.configFile."wlogout/layout".source =
      ./dotfiles/wlogout/layout;

    xdg.configFile."wlogout/style.css".source =
      ./dotfiles/wlogout/style.css;

    programs.waybar = {
      enable = true;

      settings = import ./waybar-settings.nix { inherit pkgs; };

      style = builtins.readFile ./dotfiles/waybar/style.css;
    };

  };
}