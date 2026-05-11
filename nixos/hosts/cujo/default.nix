{ hostIp4Address, hostInterface, hostName, nixosVersion, remoteBackupRoot, ... }:

{
  imports = [
    ../../modules/bare-metal
    ../../modules/tailscale

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
  };

  services.homelab.managedState.schedule = "*:20";

  homelab.sshKeyForLabUser = true;

  homelab.managedDirectories.entries = {
    test_directory = {
      local = "/home/lab/backup-restore";
      remote = "${remoteBackupRoot}/backup-restore";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };
}