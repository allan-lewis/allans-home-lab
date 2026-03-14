{ config, pkgs, lib, ... }:

{
  imports = [
    ../../profiles/base
    ../../profiles/devops
    
    ./tmpfiles.nix
    ./secrets.nix
    ./lab-user.nix
    ./services.nix
    ./boot.nix
    ./networking.nix
  ];

  system.stateVersion = "25.11";
}