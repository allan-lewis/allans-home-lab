{ backupRoot, hostAddress, hostName, hostInterface, ... }:

{
  imports = [
    ../bare-metal.nix

    ../authentik
    ../cloudflare.nix
    ../gatus.nix
    ../prometheus-stack
    ../s3-mirror
    ../traefik.nix
    ../twingate/modest-anteater.nix

    ../../modules/tailscale
  ];

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };

  homelab.managedDirectories.entries = {
    s3_mirror = {
      local = "/var/lib/s3-mirror";
      remote = "${backupRoot}/s3-mirror";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };

  homelab.managedStateSchedule = "*:30";
}