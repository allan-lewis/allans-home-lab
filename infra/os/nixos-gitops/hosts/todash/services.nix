{ config, lib, ... }:

let
  featureFlagBackup = false;
  featureFlagDevOps = false;
  featureFlagNodeExporter = true;
  featureFlagRestore = false;
  featureFlagPostgresDump = false;
  featureFlagS3Mirror = false;
  featureFlagTailscale = false;
in
{
  virtualisation.docker.enable = true;

  services.qemuGuest.enable = true;
  services.cloud-init.enable = true;
  services.cloud-init.network.enable = true;

  services.homelab.hello = {
    enable = true;
    intervalSeconds = 15;
  };

  services.prometheus.exporters.node = lib.mkIf featureFlagNodeExporter {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9100;
    openFirewall = true;
    enabledCollectors = [ "textfile" ];
    extraFlags = [
      "--collector.textfile.directory=/var/lib/node_exporter/textfile_collector"
    ];
  };

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

  services.homelab.devCheckouts = lib.mkIf featureFlagDevOps {
    enable = true;
    schedule = "hourly";
    rootDir = "/home/lab/src";
    user = "lab";

    repos = [
      {
        repo = "git@github.com:allan-lewis/allans-home-lab.git";
        dest = "allans-home-lab";
        version = "main";
      }
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

  services.homelab.doppler = lib.mkIf featureFlagDevOps {
    enable = true;
    user = "lab";
    scopeDir = "/home/lab/src";
    tokenFile = "/var/lib/homelab-secrets/doppler/doppler_token";
    project = "orchestrator";
    dopplerConfig = "mat";
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