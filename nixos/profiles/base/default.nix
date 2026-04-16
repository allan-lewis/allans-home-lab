{ config, lib, options, pkgs, ... }:

let
  inherit (lib) mkOption types;
in
{
  imports = [
    ../observability
    ../podman

    ./lab-user.nix
    ./tmpfiles.nix
  ];

  options.homelab = {
    managedStateSchedule = mkOption {
      type = types.str;
      default = "hourly";
      description = "systemd OnCalendar schedule for services.homelab.managedState.";
    };
  };

  config = {
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";

    sops.secrets.root_ssh_private_key = {
      sopsFile = ../../secrets/ssh.yaml;
      key = "root_ssh_private_key";
      path = "/root/.ssh/id_ed25519";
      owner = "root";
      group = "root";
      mode = "0600";
    };

    system.activationScripts.rootSshPublicKey = {
      text = ''
        if [ -f /root/.ssh/id_ed25519 ]; then
          ${pkgs.openssh}/bin/ssh-keygen -y -f /root/.ssh/id_ed25519 > /root/.ssh/id_ed25519.pub
          chown root:root /root/.ssh/id_ed25519.pub
          chmod 0644 /root/.ssh/id_ed25519.pub
        fi
      '';
    };

    system.activationScripts.managedStateRestoreAfterSwitch = lib.mkIf config.services.homelab.managedState.enable {
      deps = [ "rootSshPublicKey" "etc" ];
      text = ''
        mkdir -p /run/nixos
        if ! grep -qxF 'homelab-task-managed-state-restore.service' /run/nixos/activation-restart-list 2>/dev/null; then
          printf '%s\n' 'homelab-task-managed-state-restore.service' >> /run/nixos/activation-restart-list
        fi
      '';
    };

    security.sudo.enable = true;
    security.sudo.wheelNeedsPassword = false;

    time.timeZone = "UTC";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nixpkgs.config.allowUnfree = true;

    services.openssh.enable = true;
    services.openssh.settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };

    services.openssh.extraConfig = ''
      AllowUsers lab
    '';

    environment.systemPackages = with pkgs; [
      btop
      cmatrix
      curl
      dnsutils
      gcc
      ghostty.terminfo
      git
      jq
      net-tools
      python3
      trash-cli
      tree
      tree-sitter
      unzip
      wget
    ];

    services.homelab.hello = {
      enable = true;
      intervalSeconds = 15;
    };

    services.homelab.managedState = {
      enable = true;
      schedule = config.homelab.managedStateSchedule;
      persistent = false;
    };
  };
}