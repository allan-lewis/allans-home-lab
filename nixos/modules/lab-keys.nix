{ pkgs, ... }:

{
  sops.secrets.lab_ssh_private_key = {
    sopsFile = ../secrets/ssh.yaml;
    key = "root_ssh_private_key";
    path = "/home/lab/.ssh/id_ed25519";
    owner = "lab";
    group = "lab";
    mode = "0600";
  };

  system.activationScripts.labSshPublicKey = {
    text = ''
      if [ -f /home/lab/.ssh/id_ed25519 ]; then
        ${pkgs.openssh}/bin/ssh-keygen -y -f /home/lab/.ssh/id_ed25519 > /home/lab/.ssh/id_ed25519.pub
        chown lab:lab /home/lab/.ssh/id_ed25519.pub
        chmod 0644 /home/lab/.ssh/id_ed25519.pub
      fi
    '';
  };
}