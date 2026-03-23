{ config, lib, ... }:

let
  featureFlagPostgresDump = false;
  featureFlagS3Mirror = false;
  featureFlagTailscale = false;
in
{
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

}