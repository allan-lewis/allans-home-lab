{ pkgs, ... }:

let
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

    #: write style/css to user's config folder
    xdg.configFile."wlogout/style.css".source =
      ./dotfiles/wlogout/style.css;
  };
}