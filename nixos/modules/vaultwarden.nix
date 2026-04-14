{ nasRootFolder, ... }:

{
  homelab.managedDirectories.entries = {
    vaultwarden = {
      local = "/var/lib/vaultwarden";
      remote = "${nasRootFolder}/vaultwarden";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };
}