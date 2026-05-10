{ pkgs, ... }:

{
    virtualisation.docker.enable = true;

    users.users.lab.extraGroups = [ "docker" ];

    environment.systemPackages = with pkgs; [
      docker-compose
    ];
}