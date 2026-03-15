{ config, pkgs, lib, ... }:

{
  imports = [
    ../../profiles/bare-metal
    ../../profiles/base
    ../../profiles/docker
  ];

  networking.hostName = "cujo";

  system.stateVersion = "25.11";
}