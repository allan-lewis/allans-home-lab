{ remoteBackupRoot, config, ... }:

{
  imports = [
    ../../modules/oci-containers/checkmk
  ];

  homelab.managedDirectories.entries = {
    checkmk = {
      local = config.services.checkmk.dataDir;
      remote = "${remoteBackupRoot}/checkmk";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
      # These are OMD/Checkmk runtime paths that churn continuously while the
      # site is live, so a backup rsync can race their rewrite/delete cycle
      # and hit "file has vanished" (exit 24). Only applied to backup (local
      # -> remote); restore pulls the static remote copy in full. Deliberately
      # NOT excluded: var/check_mk (autochecks/rrd/web state), var/pnp4nagios
      # /perfdata (historical graphs), var/ssl (agent-signing CA/certs).
      backupExcludes = [
        "tmp/"                    # livestatus socket, PID files, caches; recreated on site start
        "var/pnp4nagios/spool/"   # npcd perfdata queue; consumed+deleted into RRDs (observed 2026-10-22)
        "var/rrdcached/"          # rrdcached journal/socket; write-buffer, not canonical data
        "var/nagios/"             # status.dat rewritten every few seconds; rw/ is the command FIFO
        "var/redis/"              # bundled cache; persisted via continuous atomic rewrite
      ];
    };
  };
}

