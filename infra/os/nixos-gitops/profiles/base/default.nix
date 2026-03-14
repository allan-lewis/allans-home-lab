{ pkgs, ... }:

{
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  time.timeZone = "UTC";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  services.openssh.enable = true;
  services.openssh.settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  services.openssh.extraConfig = ''
    AllowUsers lab
  '';

  environment.systemPackages = with pkgs; [
    btop
    cmatrix
    curl
    ghostty.terminfo
    jq
    net-tools
    python3
    trash-cli
    tree
    tree-sitter
    unzip
  ];
}