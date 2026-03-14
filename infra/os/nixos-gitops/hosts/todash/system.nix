{ ... }:

{
  users.groups.aws = {};

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  time.timeZone = "UTC";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11";
}