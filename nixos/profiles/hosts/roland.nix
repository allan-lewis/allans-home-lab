{ hostAddress, hostName, hostInterface, hostTimeZone, lib, ... }:

{
  imports = [
    ../bare-metal.nix
    ../desktop.nix
    ../devops.nix
  ];

  _module.args = {
    dopplerProject = "homelab";
    dopplerConfig = "stg";
    dopplerTokenKey = "homelab_stg";
  };

  time.timeZone = lib.mkForce hostTimeZone;

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };
}