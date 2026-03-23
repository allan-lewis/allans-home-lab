{ backupRemotePrefix, ... }:

let
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/todash.toml);
  hostName = inventoryConfig.hostname;
  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  imports = [
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

  services.homelab.containers.it-tools = {
    image = "corentinth/it-tools@sha256:6f177c156b9466610e0f2093e24668b78da501c66f0054f98bccb582b74ab26b";
    port = 8386;
    internalPort = 80;
  };

  services.homelab.containers.nginx = {
    image = "nginx@sha256:42e026ae5315aa0deec22fb00c364fc5ec8d9af1c4833ad5317e2a433e4de0df";
    port = 80;
  };

  ## NEEDS ENV VARS
  # services.homelab.containers.ngb = {
  #   image = "allanelewis/ngb-go@sha256:32261fc7b13d58ccb6bf8f43ea7e07bd60a9213598a05d0ea462fc223bb83ec2";
  #   port = 8080;
  # };

  system.stateVersion = "25.11";
}