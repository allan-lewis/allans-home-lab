{ pkgs, ... }:

let
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
  home-manager.users.lab = { ... }: {
    home.file.".config/wlogout/icons" = {
      source = whiteWlogoutIcons;
      recursive = true;
    };
  };
}