{ pkgs, ... }:

{
  imports = [
    ../default-user
    ../homelab-modules
    ../oci-containers
    ../prometheus-node-exporter
  ];

  config = {
    #: nixos settings
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nixpkgs.config.allowUnfree = true;

    #: time zone
    time.timeZone = "UTC";

    #: sops/age config
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";

    #: configure security
    security.sudo.enable = true;
    security.sudo.wheelNeedsPassword = false;

    #: system-wide packages
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

    #: nixos-managed directories
    systemd.tmpfiles.rules = [
      "d /home/lab/.config 0755 lab lab -"
      "d /home/lab/.config/zsh 0755 lab lab -"
      "d /home/lab/.ssh 0700 lab lab -"

      "d /root/.ssh 0700 root root -"

      "d /etc/allans-home-lab 0755 root root -"
      "d /etc/allans-home-lab/managed-directories 0755 root root -"
      "d /etc/allans-home-lab/secrets 0700 root root -"
    ];

    #: configure ssh
    services.openssh.enable = true;
    services.openssh.settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };

    services.openssh.extraConfig = ''
      AllowUsers lab
    '';

    #: root ssh keys
    sops.secrets.root_ssh_private_key = {
      sopsFile = ./secrets/ssh.yaml;
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
  };
}