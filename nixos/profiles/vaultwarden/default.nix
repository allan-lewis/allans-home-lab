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
    image = "vaultwarden/server:1.37.3@sha256:4ecafc9049c7d878c7717d1ce4f9059d706758c78b8fa42e5ead21f4b2dfc770";
  };
}