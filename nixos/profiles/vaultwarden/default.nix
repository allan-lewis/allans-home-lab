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
    image = "vaultwarden/server:1.35.8@sha256:1e6ebcede9be39fc1a7617eec4c984899edd954c09bd651b121cd89732e7aef4";
  };
}