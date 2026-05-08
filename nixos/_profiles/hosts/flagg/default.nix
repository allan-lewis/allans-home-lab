{ backupRoot, hostAddress, hostName, hostInterface, ... }:

{
  imports = [
    ../../../_modules/bare-metal
    ../../../_modules/tailscale
    # ../bare-metal.nix

    ../../../_profiles/cloudflare
    ../../../_profiles/gatus
    ../../../_profiles/prometheus-stack
    ../../../_profiles/traefik

    # ../authentik
    # ../prometheus-stack
    # ../s3-mirror
    # ../twingate/modest-anteater.nix
  ];

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = hostInterface;
    address = hostAddress;
  };

  # homelab.managedDirectories.entries = {
  #   s3_mirror = {
  #     local = "/var/lib/s3-mirror";
  #     remote = "${backupRoot}/s3-mirror";
  #     restore = true;
  #     backup = true;
  #     owner = "root";
  #     group = "root";
  #     mode = "0755";
  #   };
  # };

  services.homelab.managedState.schedule = "*:30";
}