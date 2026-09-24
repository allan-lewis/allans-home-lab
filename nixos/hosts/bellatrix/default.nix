{ hostDns, hostIp4Address, hostIp4Gateway, hostName, hostInterface, nixosVersion, lib, remoteBackupRoot, ... }:

{
  imports = [
    ../../modules/bare-metal
    ../../modules/tailscale

    ../../profiles/desktop
    ../../profiles/devops
  ];

  _module.args = {
    dopplerConfig = "prd";
    dopplerProject = "homelab";
    dopplerTokenKey = "homelab_prd";
  };

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostIp4Address;
    gateway = hostIp4Gateway;
    dns = hostDns;
  };

  time.timeZone = lib.mkForce "America/New_York";

  services.homelab.managedState.schedule = "*:05";

  homelab.sshKeyForLabUser = true;

  homelab.labUser.enablePassword = true;
}

