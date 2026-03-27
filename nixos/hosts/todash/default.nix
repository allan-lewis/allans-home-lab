{ backupRemotePrefix, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/todash.toml);
  hostName = inventoryConfig.hostname;
  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  imports = [
    ../../profiles/authentik
    ../../profiles/base
    ../../profiles/virtual-machine
  ];

  networking.hostName = hostName;

  homelab.managedDirectories.entries = {
    managed_dir_0 = {
      local = "/home/lab/managed-dir-0";
      remote = "${defaultRemoteNasPerHostBackupVolume}/managed-dir-0";
      restore = true;
      backup = true;
      owner = "lab";
      group = "lab";
      mode = "0755";
    };

    managed_dir_1 = {
      local = "/home/lab/managed-dir-1";
      remote = "${defaultRemoteNasPerHostBackupVolume}/managed-dir-1";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };

  services.homelab.authentikCompose = {
    enable = true;
    version = "2026.2";
    httpPort = 9180;
    httpsPort = 9143;
  };

  system.stateVersion = "25.11";
}