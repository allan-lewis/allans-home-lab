{ hostIp4Address, hostName, hostInterface, nixosVersion, lib, ... }:

{
  imports = [
    ../../modules/bare-metal
    ../../modules/tailscale

    ../../profiles/desktop
    ../../profiles/devops
  ];

  _module.args = {
    dopplerConfig = "stg";
    dopplerProject = "homelab";
    dopplerTokenKey = "homelab_stg";
  };

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostIp4Address;
  };

  time.timeZone = lib.mkForce "America/New_York";

  services.homelab.managedState.schedule = "*:05";

  homelab.sshKeyForLabUser = true;

  homelab.labUser.enablePassword = true;
}