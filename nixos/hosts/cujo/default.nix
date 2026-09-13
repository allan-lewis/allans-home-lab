{ hostIp4Address, hostInterface, hostName, nixosVersion, remoteBackupRoot, ... }:

{
  imports = [
    ../../modules/virtual-machine
    ../../modules/tailscale

    ../../profiles/devops
    ../../profiles/gatus
    ../../profiles/traefik
  ];

  _module.args = {
    dopplerConfig = "prd";
    dopplerProject = "homelab";
    dopplerTokenKey = "homelab_prd";
  };

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  services.homelab.managedState.schedule = "*:20";

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
