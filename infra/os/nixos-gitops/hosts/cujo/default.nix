{ ... }:

{
  imports = [
    ../../profiles/bare-metal
    ../../profiles/base
    ../../profiles/devops
    ../../profiles/docker
    ../../profiles/tailscale
  ];

  networking.hostName = "cujo";

  homelab.bareMetal.interface = "eth1";
  homelab.bareMetal.address = "192.168.86.219";

  system.stateVersion = "25.11";
}