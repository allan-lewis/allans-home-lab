{ pkgs, ... }:

{
  
  environment.systemPackages = with pkgs; [
    awscli2
  ];

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

  systemd.tmpfiles.rules = [
    "d /root/.aws 0700 root root -"
    "L+ /root/.aws/config - - - - /etc/aws-config"
    "L+ /root/.aws/credentials - - - - /var/lib/homelab-secrets/aws/credentials"
  ];
}