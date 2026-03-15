{ ... }:

{
  virtualisation.docker.enable = true;

  systemd.tmpfiles.rules = [
    "d /opt/docker-compose 0750 root root -"
  ];
}