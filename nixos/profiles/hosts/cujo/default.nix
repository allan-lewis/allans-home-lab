{ backupRoot, hostAddress, hostName, hostInterface, ... }:

{
  imports = [
    ../../../modules/bare-metal
    ../../../modules/tailscale

    ../../../profiles/devops
  ];

  _module.args = {
    dopplerConfig = "prd";
    dopplerProject = "homelab";
    dopplerTokenKey = "homelab_prd";
  };

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };

  services.homelab.managedState.schedule = "*:20";

  homelab.sshKeyForLabUser = true;

  homelab.managedDirectories.entries = {
    test_directory = {
      local = "/home/lab/backup-restore";
      remote = "${backupRoot}/backup-restore";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };
  };
}