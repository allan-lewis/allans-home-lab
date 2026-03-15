{ ... }:

{
  systemd.tmpfiles.rules = [
    "d /home/lab/.config 0755 lab lab -"
    "d /home/lab/.config/zsh 0755 lab lab -"
    "d /root/.ssh 0700 root root -"

    # "d /var/lib/postgres-db-dumps 0755 root root -"
    # "d /var/lib/tailscale 0700 root root -"

    "d /etc/allans-home-lab 0755 root root -"
    "d /etc/allans-home-lab/managed-directories 0755 root root -"
    "d /etc/allans-home-lab/secrets 0700 root root -"
  ];
}