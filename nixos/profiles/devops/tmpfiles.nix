{ ... }:

{
  systemd.tmpfiles.rules = [
    "d /home/lab/.ssh 0700 lab lab -"

    "d /var/lib/homelab-secrets 0711 root root -"
    "d /var/lib/homelab-secrets/doppler 0700 lab lab -"

    ## TODO: RELY ON AWS-CREDENTIALS FOR THIS
    "d /var/lib/homelab-secrets/aws 0750 root aws -"
    "d /root/.aws 0700 root root -"
    "d /home/lab/.aws 0700 lab lab -"

    "L+ /root/.aws/config - - - - /etc/aws-config"
    "L+ /home/lab/.aws/config - - - - /etc/aws-config"

    "L+ /root/.aws/credentials - - - - /var/lib/homelab-secrets/aws/credentials"
    "L+ /home/lab/.aws/credentials - - - - /var/lib/homelab-secrets/aws/credentials"
  ];
}