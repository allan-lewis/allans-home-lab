{ remoteBackupRoot, hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/virtual-machine
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;

  services.homelab.managedState.schedule = "*:55";

  homelab.managedDirectories.entries = {
    managed_dir_0 = {
      local = "/home/lab/managed-dir-0";
      remote = "${remoteBackupRoot}/managed-dir-0";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };

    managed_dir_1 = {
      local = "/home/lab/managed-dir-1";
      remote = "${remoteBackupRoot}/managed-dir-1";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };
}