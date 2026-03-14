{ config, pkgs, lib, ... }:

{
  imports = [
    ./tmpfiles.nix
    ./secrets.nix
    ./packages.nix
    ./lab-user.nix
    ./services.nix
    ./boot.nix
    ./networking.nix
    ./system.nix
  ];
}