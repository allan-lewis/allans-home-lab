{ lib, ... }:

{
  options.homelab.desktop.themes = lib.mkOption {
    type = lib.types.attrs;
    default = {
      nix-blue = {
        wallpaper = ../dotfiles/wallpaper/nix-wallpaper-binary-blue.png;
        starshipPalette = "catppuccin_mocha";
      };

      gruvbox-dark = {
        wallpaper = ../dotfiles/wallpaper/gruvbox-rainbow-nix.png;
        starshipPalette = "gruvbox_dark_hard";
      };
    };
  };
}