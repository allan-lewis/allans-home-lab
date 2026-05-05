{ backupRoot, hostAddress, hostName, hostInterface, ... }:

{
  imports = [
    ../../../_modules/bare-metal
    ../../../_modules/tailscale

    ../../../_profiles/doppler
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