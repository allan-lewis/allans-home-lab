{ config, lib, ... }:

let
  featureFlagBackup = false;
  featureFlagRestore = false;
  featureFlagPostgresDump = false;
  featureFlagS3Mirror = false;
  featureFlagTailscale = false;
in
{
  services.homelab.managedDirectories = lib.mkIf featureFlagRestore {
    enable = false;
    writablePaths = [
      "/home/lab/managed-dir-0"
      "/home/lab/managed-dir-1"
    ];
  };

  services.homelab.backupRunner = lib.mkIf featureFlagBackup {
    enable = false;
    schedule = "*-*-* *:30:00";

    rsyncFlags =
      lib.splitString " "
        "-aHAX --numeric-ids --delete-delay --partial --partial-dir=.rsync-partial --human-readable --sparse --mkpath";

    readablePaths = [
      "/home/lab/managed-dir-0"
      "/home/lab/managed-dir-1"
    ];
  };

  services.homelab.s3LocalMirror = lib.mkIf featureFlagS3Mirror {
    enable = false;
    schedule = "Sat *-*-* 07:00:00";
    syncFlags = "--delete --only-show-errors";
    buckets = [ ];
  };

  services.homelab.postgresDbBackup = lib.mkIf featureFlagPostgresDump {
    enable = false;
    schedule = "*-*-* 05:00:00";

    db = "";
    user = "";
    container = "";
    extraArgs = "";

    backupDir = "/var/lib/postgres-db-dumps";
    passwordFile = "/etc/allans-home-lab/secrets/postgres_dump_pass";
  };

  services.tailscale = lib.mkIf featureFlagTailscale {
    enable = true;
    authKeyFile = "/run/secrets/tailscale-authkey";
    extraUpFlags = [
      "--accept-dns=true"
    ];
  };

  networking.firewall.trustedInterfaces =
    lib.mkIf config.services.tailscale.enable [ "tailscale0" ];
}