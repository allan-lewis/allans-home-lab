{ ... }:

{
  imports = [
    ../../profiles/base
    ../../profiles/docker
    ../../profiles/virtual-machine
  ];

  networking.hostName = "todash";

  system.stateVersion = "25.11";
}