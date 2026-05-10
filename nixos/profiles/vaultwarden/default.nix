{ backupRoot, config, ... }:

{
  imports = [
    ../../modules/oci-containers/vaultwarden
  ];

  homelab.managedDirectories.entries = {
    vaultwarden = {
      local = "/var/lib/vaultwarden";
      remote = "${backupRoot}/vaultwarden";
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
  };
}