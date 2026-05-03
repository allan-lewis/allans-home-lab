{ config, lib, ... }:

{
  imports = [
    ./hello
    ./managed-state
    ./postgres-backup
    ./s3-mirror
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
  system.activationScripts.managedStateRestoreAfterSwitch = lib.mkIf config.services.homelab.managedState.enable {
    deps = [ "rootSshPublicKey" "etc" ];
    text = ''
      mkdir -p /run/nixos
      if ! grep -qxF 'homelab-task-managed-state-restore.service' /run/nixos/activation-restart-list 2>/dev/null; then
        printf '%s\n' 'homelab-task-managed-state-restore.service' >> /run/nixos/activation-restart-list
      fi
    '';
  };
}
