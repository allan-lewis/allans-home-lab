{ hostIp4Address, hostName, hostInterface, nixosVersion, lib, remoteBackupRoot, ... }:

{
  imports = [
    ../../modules/bare-metal
    ../../modules/rust
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
 
  homelab.managedDirectories.entries = {
    test_directory = {
      local = "/home/lab/rust-playground/";
      remote = "${remoteBackupRoot}/rust-playground";
      restore = false;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };
}
