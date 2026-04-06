{ ... }:

{
  imports = [
    ../../modules/authentik.nix
    ../../modules/postgres-db-backup.nix
  ];

  services.homelab.authentikCompose = {
    enable = true;
    version = "2025.10.3";
    httpPort = 9180;
    httpsPort = 9143;
  };

  services.homelab.postgresDbBackup = {
    enable = true;
    schedule = "*-*-* 05:00:00";

    db = "authentik";
    user = "authentik";
    container = "authentik-postgresql-1";
    extraArgs = "";
  };

}