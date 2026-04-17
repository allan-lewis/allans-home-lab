{ hostAddress, hostName, hostInterface, hostTimeZone, lib, ... }:

{
  time.timeZone = lib.mkForce hostTimeZone;

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };
}