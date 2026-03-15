{ config, pkgs, lib, ... }:

{
  imports = [
    ../../profiles/base
    ../../profiles/devops
    ../../profiles/docker
    ../../profiles/virtual-machine
  ];

  networking.hostName = "todash";

  system.stateVersion = "25.11";
}