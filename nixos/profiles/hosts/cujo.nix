{ backupRoot, hostAddress, hostName, hostInterface, ... }:

{
  imports = [
    ../bare-metal.nix
    ../devops.nix

    ../../modules/tailscale
  ];

  _module.args = {
    dopplerProject = "homelab";
    dopplerConfig = "prd";
    dopplerTokenKey = "homelab_prd";
  };

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };

  homelab.managedStateSchedule = "*:20";

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