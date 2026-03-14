{ pkgs, ... }:

{
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets.root_ssh_private_key = {
    sopsFile = ./secrets/ssh.yaml;
    key = "root_ssh_private_key";
    path = "/root/.ssh/id_ed25519";
    owner = "root";
    group = "root";
    mode = "0600";
  };

  sops.secrets.lab_ssh_private_key = {
    sopsFile = ./secrets/ssh.yaml;
    key = "root_ssh_private_key";
    path = "/home/lab/.ssh/id_ed25519";
    owner = "lab";
    group = "lab";
    mode = "0600";
  };

  sops.secrets.doppler_token = {
    sopsFile = ./secrets/doppler.yaml;
    key = "doppler_token";
    path = "/var/lib/homelab-secrets/doppler/doppler_token";
    owner = "lab";
    group = "lab";
    mode = "0600";
  };

  sops.secrets.aws_credentials = {
    sopsFile = ./secrets/aws.yaml;
    key = "aws_credentials";
    path = "/var/lib/homelab-secrets/aws/credentials";
    owner = "root";
    group = "aws";
    mode = "0640";
  };

  environment.etc."aws-config".text = ''
    [default]
    region = us-east-1
    output = json
    cli_pager =
  '';

  sops.secrets.tailscale_authkey = {
    sopsFile = ./secrets/tailscale.yaml;
    key = "tailscale_authkey";
    path = "/run/secrets/tailscale-authkey";
    owner = "root";
    group = "root";
    mode = "0400";
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