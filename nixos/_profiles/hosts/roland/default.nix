{ hostAddress, hostName, hostInterface, hostTimeZone, lib, ... }:

{
  imports = [
    ../../../_modules/bare-metal
    ../../../_modules/tailscale

    ../../../_profiles/devops
  ];

  _module.args = {
    dopplerConfig = "stg";
    dopplerProject = "homelab";
    dopplerTokenKey = "homelab_stg";
  };

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };

  time.timeZone = lib.mkForce hostTimeZone;

  services.homelab.managedState.schedule = "*:05";

  homelab.sshKeyForLabUser = true;
}