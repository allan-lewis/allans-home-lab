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
    image = "vaultwarden/server:1.37.1@sha256:e9efdf001bf0d68c21f2cbfb8e1d9b5961a7ca9c85e0a7e58bf51a13b997d744";
  };
}