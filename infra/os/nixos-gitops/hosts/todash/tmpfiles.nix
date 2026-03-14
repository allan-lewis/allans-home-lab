{ ... }:

{
  systemd.tmpfiles.rules = [
    "d /home/lab/.ssh 0700 lab lab -"
    "d /home/lab/.config 0755 lab lab -"
    "d /home/lab/.config/zsh 0755 lab lab -"
    "d /root/.ssh 0700 root root -"

    "d /var/lib/node_exporter/textfile_collector 0755 root root -"
    "d /opt/docker-compose 0750 root root -"

    "d /home/lab/managed-dir-0 0755 lab lab -"
    "d /home/lab/managed-dir-1 0755 root root -"

    "d /var/lib/homelab-secrets 0711 root root -"
    "d /var/lib/homelab-secrets/doppler 0700 lab lab -"

    "d /var/lib/postgres-db-dumps 0755 root root -"
    "d /var/lib/tailscale 0700 root root -"

    "d /etc/allans-home-lab 0755 root root -"
    "d /etc/allans-home-lab/managed-directories 0755 root root -"
    "d /etc/allans-home-lab/secrets 0700 root root -"

    "d /var/lib/homelab-secrets/aws 0750 root aws -"
    "d /root/.aws 0700 root root -"
    "d /home/lab/.aws 0700 lab lab -"

    "L+ /root/.aws/config - - - - /etc/aws-config"
    "L+ /home/lab/.aws/config - - - - /etc/aws-config"

    "L+ /root/.aws/credentials - - - - /var/lib/homelab-secrets/aws/credentials"
    "L+ /home/lab/.aws/credentials - - - - /var/lib/homelab-secrets/aws/credentials"
  ];
}