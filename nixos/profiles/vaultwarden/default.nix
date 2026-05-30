{ remoteBackupRoot, config, ... }:

{
  imports = [
    ../../modules/oci-containers/vaultwarden
  ];

  homelab.managedDirectories.entries = {
    vaultwarden = {
      local = "/var/lib/vaultwarden";
      remote = "${remoteBackupRoot}/vaultwarden";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };

  sops.secrets.vaultwarden_env = {
    sopsFile = ./vaultwarden.env;
    format = "dotenv";
    key = "";
  };

  services.homelab.vaultwarden = {
    enable = true;
    environmentFile = config.sops.secrets.vaultwarden_env.path;
    image = "vaultwarden/server:1.36.0@sha256:ae4bcc7bf8ac933eb1854fe3b849c74bd94dffef56c2490f9fdeac0c3f916d92";
  };
}