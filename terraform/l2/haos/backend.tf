terraform {
  backend "s3" {
    bucket = "gitops-homelab-orchestrator-tf"
    key    = "l2/haos/terraform.tfstate"
    region = "us-east-1"
  }
}

