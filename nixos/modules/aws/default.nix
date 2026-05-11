{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types;
in
{
  options.homelab.awsCredentialsForLabUser = mkOption {
    type = types.bool;
    default = false;
    description = "Expose the shared AWS credentials/config to the lab user.";
  };

  config = mkMerge [
    {
      environment.systemPackages = with pkgs; [
        awscli2
      ];

      sops.secrets.aws_credentials = {
        sopsFile = ./aws.yaml;
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

    (mkIf config.homelab.awsCredentialsForLabUser {
      users.users.lab.extraGroups = [ "aws" ];

      systemd.tmpfiles.rules = [
        "d /home/lab/.aws 0700 lab lab -"
        "L+ /home/lab/.aws/config - - - - /etc/aws-config"
        "L+ /home/lab/.aws/credentials - - - - /var/lib/homelab-secrets/aws/credentials"
      ];
    })
  ];
}