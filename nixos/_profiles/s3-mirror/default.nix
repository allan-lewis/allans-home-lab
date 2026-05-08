{ backupRoot, ... }:

{
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

  services.homelab.s3LocalMirror = {
    enable = true;

    schedule = "Sat *-*-* 07:00:00";

    syncFlags = "--delete --only-show-errors";

    buckets = [
      "gitops-homelab-orchestrator-disks"
      "gitops-homelab-orchestrator-haos"
      "gitops-homelab-orchestrator-tf"
    ];
  }; 
}