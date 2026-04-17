{ hostName, ipAddress, lib, ... }:

{
  time.timeZone = lib.mkForce "America/New_York"; ## TODO: Source this from args

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = "enp4s0"; ## TODO: Source this from args
    address = ipAddress;
  };
}