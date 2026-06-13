{ lib, ... }:

{
  options.homelab.desktop.themes = lib.mkOption {
    type = lib.types.attrs;
    default = {
      nix-blue = {
        wallpaper = ../dotfiles/wallpaper/nix-wallpaper-binary-blue.png;
        starshipPalette = "catppuccin_mocha";

        colors = {
          text = "rgb(111, 141, 184)";
          border = "rgb(111, 141, 184)";
          borderHover = "rgb(143, 168, 201)";
          button = "rgb(30, 45, 74)";
          buttonHover = "rgb(111, 141, 184)";
          buttonHoverText = "#1e2d4a";
          window = "rgba(20, 30, 50, 0.78)";
        };
      };

      gruvbox-dark = {
        wallpaper = ../dotfiles/wallpaper/gruvbox-rainbow-nix.png;
        starshipPalette = "gruvbox_dark_hard";

        colors = {
          text = "rgb(235, 219, 178)";        # fg
          border = "rgb(214, 93, 14)";        # orange
          borderHover = "rgb(250, 189, 47)";  # yellow
          button = "rgb(40, 40, 40)";         # bg0
          buttonHover = "rgb(214, 93, 14)";   # orange
          buttonHoverText = "rgb(40, 40, 40)";
          window = "rgba(29, 32, 33, 0.78)";  # dark bg
        };
      };
    };
  };
}