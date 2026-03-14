{ config, pkgs, lib, ... }:

{
  imports = [
    ../../profiles/base
    
    ./tmpfiles.nix
    ./secrets.nix
    ./packages.nix
    ./lab-user.nix
    ./services.nix
    ./boot.nix
    ./networking.nix
  ];
}