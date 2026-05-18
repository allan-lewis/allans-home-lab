{ remoteBackupRoot, config, ... }:

let
  authentikVersion = "2026.2.3";
in
{
  imports = [
    ../../modules/authentik
  ];

  sops.secrets.authentik_pg_pass = {
    sopsFile = ./authentik.yaml;
    key = "authentik/pg_pass";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets.authentik_secret_key = {
    sopsFile = ./authentik.yaml;
    key = "authentik/secret_key";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.templates."authentik.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      AUTHENTIK_TAG=${authentikVersion}
      COMPOSE_PORT_HTTP=9180
      COMPOSE_PORT_HTTPS=9143
      PG_PASS=${config.sops.placeholder.authentik_pg_pass}
      AUTHENTIK_SECRET_KEY=${config.sops.placeholder.authentik_secret_key}
    '';
  };

  services.homelab.authentikCompose = {
    enable = true;
    version = authentikVersion;
    httpPort = 9180;
    httpsPort = 9143;
    environmentFile = config.sops.templates."authentik.env".path;
  };

  services.homelab.postgresDbBackup = {
    enable = true;
    schedule = "*-*-* 05:00:00";

    db = "authentik";
    user = "authentik";
    container = "authentik-postgresql-1";
    extraArgs = "";
    passwordFile = config.sops.secrets.authentik_pg_pass.path;
  };

  homelab.managedDirectories.entries = {
    postgres_backup = {
      local = "/var/lib/postgres-db-dumps";
      remote = "${remoteBackupRoot}/authentik/db-dumps";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };
}