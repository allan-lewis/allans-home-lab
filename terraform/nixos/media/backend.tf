terraform {
  backend "s3" {
    bucket = "gitops-homelab-orchestrator-tf"
    key    = "l2/nixos_media/terraform.tfstate"
    region = "us-east-1"
  }
}
