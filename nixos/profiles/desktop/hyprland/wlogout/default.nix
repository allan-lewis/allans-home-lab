{ config, lib, pkgs, ... }:

let
  #: get wlogout colors from selected desktop theme
  wlogoutColors = config.homelab.desktop.wlogout.colors;

  #: read wlogout CSS template
  wlogoutStyleTemplate = builtins.readFile ./dotfiles/wlogout/style.css;

  #: render wlogout CSS using selected theme colors
  wlogoutStyle = builtins.replaceStrings
    [
      "@TEXT@"
      "@WINDOW@"
      "@BORDER@"
      "@BORDER_HOVER@"
      "@BUTTON@"
      "@BUTTON_HOVER@"
      "@BUTTON_HOVER_TEXT@"
    ]
    [
      wlogoutColors.text
      wlogoutColors.window
      wlogoutColors.border
      wlogoutColors.borderHover
      wlogoutColors.button
      wlogoutColors.buttonHover
      wlogoutColors.buttonHoverText
    ]
    wlogoutStyleTemplate;

  #: create custom white icons for wlogout
  whiteWlogoutIcons = pkgs.runCommand "wlogout-icons-white" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p "$out"

    for icon in lock logout reboot shutdown; do
      src="${pkgs.wlogout}/share/wlogout/icons/$icon.png"

      magick "$src" \
        -channel RGB \
        -fill white \
        -colorize 100 \
        +channel \
        "$out/$icon.png"
    done
  '';
in
{
  #: define wlogout theme color option
  options.homelab.desktop.wlogout.colors = lib.mkOption {
    type = lib.types.attrs;
    description = "Theme colors used to render wlogout CSS.";
  };

  config = {
    #: write white icons to user's config folder
    home-manager.users.lab = { ... }: {
      home.file.".config/wlogout/icons" = {
        source = whiteWlogoutIcons;
        recursive = true;
      };

      #: install wlogout-specific packages
      home.packages = with pkgs; [
        wlogout
      ];

      #: write layout to user's config folder
      xdg.configFile."wlogout/layout".source =
        ./dotfiles/wlogout/layout;

      #: write rendered style/css to user's config folder
      xdg.configFile."wlogout/style.css".text =
        wlogoutStyle;
    };
  };
}