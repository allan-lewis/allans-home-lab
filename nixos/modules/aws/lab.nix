{ ... }:

{
  imports = [
    ./root.nix
  ];

  users.users.lab.extraGroups = [ "aws" ];

  systemd.tmpfiles.rules = [
    "d /home/lab/.aws 0700 lab lab -"
    "L+ /home/lab/.aws/config - - - - /etc/aws-config"
    "L+ /home/lab/.aws/credentials - - - - /var/lib/homelab-secrets/aws/credentials"
  ];
}