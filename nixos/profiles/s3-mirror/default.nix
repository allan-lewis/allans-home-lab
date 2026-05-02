{ ... }:

{
  imports = [
    ../../modules/aws/root.nix
    ../../modules/s3-local-mirror.nix
  ];

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