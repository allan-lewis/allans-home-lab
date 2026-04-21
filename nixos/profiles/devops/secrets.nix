{ pkgs, ... }:

{

  # sops.secrets.lab_ssh_private_key = {
  #   sopsFile = ../../secrets/ssh.yaml;
  #   key = "root_ssh_private_key";
  #   path = "/home/lab/.ssh/id_ed25519";
  #   owner = "lab";
  #   group = "lab";
  #   mode = "0600";
  # };

  # sops.secrets.doppler_token = {
  #   sopsFile = ../../secrets/doppler.yaml;
  #   key = "doppler_token";
  #   path = "/var/lib/homelab-secrets/doppler/doppler_token";
  #   owner = "lab";
  #   group = "lab";
  #   mode = "0600";
  # };

  ## TODO REPLACE WITH AWS-CREDENTIALS 
  sops.secrets.aws_credentials = {
    sopsFile = ../../secrets/aws.yaml;
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

  # system.activationScripts.labSshPublicKey = {
  #   text = ''
  #     if [ -f /home/lab/.ssh/id_ed25519 ]; then
  #       ${pkgs.openssh}/bin/ssh-keygen -y -f /home/lab/.ssh/id_ed25519 > /home/lab/.ssh/id_ed25519.pub
  #       chown lab:lab /home/lab/.ssh/id_ed25519.pub
  #       chmod 0644 /home/lab/.ssh/id_ed25519.pub
  #     fi
  #   '';
  # };
}