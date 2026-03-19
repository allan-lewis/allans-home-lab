{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    google-chrome
    ghostty
  ];

  environment.variables = {
    EDITOR = "nvim";
    TERMINAL = "ghostty";
  };

  security.sudo.wheelNeedsPassword = false;

  services.printing.enable = true;

  hardware.bluetooth.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  security.rtkit.enable = true;

  fonts.packages = with pkgs; [
    dejavu_fonts
    liberation_ttf
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
  ];
}