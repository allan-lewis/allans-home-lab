{ lib, ... }:

{
  options.homelab.desktop.themes = lib.mkOption {
    type = lib.types.attrs;
    default = {
      nix-blue = {
        wallpaper = ../dotfiles/wallpaper/nix-wallpaper-binary-blue.png;
        starshipPalette = "catppuccin_mocha";

        colors = rec {
          # existing wlogout colors...
          text = "rgb(111, 141, 184)";
          border = "rgb(111, 141, 184)";
          borderHover = "rgb(143, 168, 201)";
          button = "rgb(30, 45, 74)";
          buttonHover = "rgb(111, 141, 184)";
          buttonHoverText = "#1e2d4a";
          window = "rgba(20, 30, 50, 0.78)";

          # hyprlock colors
          lockTime = "rgb(143, 168, 201)";
          lockInputText = "rgb(111, 141, 184)";
          lockInputInner = "rgb(30, 45, 74)";
          lockInputOuter = "rgb(111, 141, 184)";
          lockInputCheck = "rgb(143, 168, 201)";
          lockInputFail = "rgb(111, 141, 184)";

          # waybar colors
          waybarText = "rgb(255, 255, 255)";
          waybarBackground = "rgb(20, 30, 50)";
          waybarIdentity = waybarText;
          waybarPower = waybarText;
          waybarClock = waybarText;
          waybarNetwork = waybarText;
          waybarStats = waybarText;
        };
      };

      gruvbox-dark = {
        wallpaper = ../dotfiles/wallpaper/gruvbox-rainbow-nix.png;
        starshipPalette = "gruvbox_dark_hard";

        colors = rec {
          gruvboxBackground = "rgb(50, 48, 47)";      # #32302f
          gruvboxRed = "rgb(220, 50, 47)";            # #dc322f
          gruvboxOrange = "rgb(254, 152, 24)";        # #fe9818
          gruvboxYellow = "rgb(223, 170, 40)";        # #dfaa28
          gruvboxGreen = "rgb(193, 194, 43)";         # #c1c22b
          gruvboxAqua = "rgb(104, 157, 166)";         # #689da6
          gruvboxPurple = "rgb(211, 154, 169)";       # #d39aa9

          # existing wlogout colors...
          text = "rgb(235, 219, 178)";
          border = "rgb(214, 93, 14)";
          borderHover = "rgb(250, 189, 47)";
          button = "rgb(40, 40, 40)";
          buttonHover = "rgb(214, 93, 14)";
          buttonHoverText = "rgb(40, 40, 40)";
          window = "rgba(29, 32, 33, 0.78)";

          # hyprlock colors
          lockTime = "rgb(250, 189, 47)";
          lockInputText = "rgb(235, 219, 178)";
          lockInputInner = "rgb(40, 40, 40)";
          lockInputOuter = "rgb(214, 93, 14)";
          lockInputCheck = "rgb(250, 189, 47)";
          lockInputFail = "rgb(204, 36, 29)";

          # waybar colors
          waybarText = "rgb(235, 219, 178)";
          waybarBackground = "rgb(40, 40, 40)";
          waybarIdentity = gruvboxOrange;
          waybarPower = gruvboxRed;
          waybarClock = gruvboxGreen;
          waybarNetwork = gruvboxAqua;
          waybarStats = gruvboxPurple;
        };
      };
    };
  };
}