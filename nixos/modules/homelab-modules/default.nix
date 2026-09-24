{ config, lib, pkgs, ... }:

{
  imports = [
    ./hello
    ./managed-state
    ./postgres-backup
    ./s3-mirror
    ./source-code
    ./task-wrapper
  ];

  #: enable the hello service by default
  services.homelab.hello = {
    enable = true;
  };

  #: enable the backup/restore service by default
  services.homelab.managedState = {
    enable = true;
    persistent = false;
  };

  #: restore managed directories after any switch
  systemd.targets.homelab-managed-state-reactivation =
    lib.mkIf config.services.homelab.managedState.enable {
      description = "Restore homelab managed state during NixOS reactivation";

      wantedBy = [ "sysinit-reactivation.target" ];
      before = [ "sysinit-reactivation.target" ];

      wants = [ "homelab-task-managed-state-restore.service" ];
      after = [ "homelab-task-managed-state-restore.service" ];
    };
}
