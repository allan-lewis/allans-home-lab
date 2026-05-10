{ pkgs, ... }:

{
  home-manager.users.lab = { ... }: {
    #: enable the mako notification daemon
    services.mako.enable = true;

    #: manage standard xdg user directories
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    #: install packages
    home.packages = with pkgs; [
      gruvbox-gtk-theme
      libnotify
      pavucontrol
      polkit_gnome
      vscodium
    ];

    #: configure ghostty
    xdg.configFile."ghostty/config".source =
      ./dotfiles/ghostty/config.ghostty;

    #: configure desktop theming
    home.sessionVariables = {
      GTK_THEME = "Gruvbox-Dark";
    };

    gtk = {
      enable = true;

      theme = {
        name = "Gruvbox-Dark";
        package = pkgs.gruvbox-gtk-theme;
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk";
    };
  };
}