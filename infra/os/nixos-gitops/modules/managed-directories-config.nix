{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
    mapAttrsToList
    filter
    concatMapStringsSep;

  cfg = config.homelab.managedDirectories;

  entriesList =
    mapAttrsToList
      (name: d:
        let
          marker =
            if d.marker != null then d.marker
            else cfg.defaults.marker;

          restoreWhen =
            if d.restoreWhen != null then d.restoreWhen
            else cfg.defaults.restoreWhen;

          backupWhen =
            if d.backupWhen != null then d.backupWhen
            else cfg.defaults.backupWhen;

          allowUninitializedBackup =
            if d.allowUninitializedBackup != null then d.allowUninitializedBackup
            else cfg.defaults.allowUninitializedBackup;

          backup =
            if d.backup != null then d.backup
            else true;

          restore =
            if d.restore != null then d.restore
            else true;
        in
        {
          inherit
            name
            marker
            restoreWhen
            backupWhen
            allowUninitializedBackup
            backup
            restore;

          local = d.local;
          remote = d.remote;
          owner = d.owner;
          group = d.group;
          mode = d.mode;
        })
      cfg.entries;

  yamlBool = b: if b then "true" else "false";

  managedDirectoriesYaml = pkgs.writeText "managed-directories.yaml" (
    ''
      version: 1
      host: "${config.networking.hostName}"

      managed_directories:
    ''
    + (
      if entriesList == [] then
        "  []\n"
      else
        concatMapStringsSep "\n" (d: ''
          - name: "${d.name}"
            local: "${d.local}"
            remote: "${d.remote}"
            owner: "${d.owner}"
            group: "${d.group}"
            mode: "${d.mode}"
            backup: ${yamlBool d.backup}
            restore: ${yamlBool d.restore}
            marker: "${d.marker}"
            restore_when: "${d.restoreWhen}"
            backup_when: "${d.backupWhen}"
            allow_uninitialized_backup: ${yamlBool d.allowUninitializedBackup}
        '') entriesList
    )
  );

  backupReadablePaths = map (d: d.local) (filter (d: d.backup) entriesList);
  restoreWritablePaths = map (d: d.local) (filter (d: d.restore) entriesList);

in
{
  options.homelab.managedDirectories = {
    defaults = mkOption {
      type = types.submodule {
        options = {
          marker = mkOption {
            type = types.str;
            default = ".initialized";
          };

          restoreWhen = mkOption {
            type = types.str;
            default = "missing_marker";
          };

          backupWhen = mkOption {
            type = types.str;
            default = "always";
          };

          allowUninitializedBackup = mkOption {
            type = types.bool;
            default = false;
          };
        };
      };
      default = {};
    };

    entries = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options = {
          local = mkOption {
            type = types.str;
          };

          remote = mkOption {
            type = types.str;
          };

          owner = mkOption {
            type = types.str;
            default = "root";
          };

          group = mkOption {
            type = types.str;
            default = "root";
          };

          mode = mkOption {
            type = types.str;
            default = "0755";
          };

          backup = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          restore = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          marker = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          restoreWhen = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          backupWhen = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          allowUninitializedBackup = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };
        };
      }));
      default = {};
    };
  };

  config = {
    environment.etc."allans-home-lab/managed-directories/config.yaml".source =
      managedDirectoriesYaml;

    services.homelab.managedDirectories.writablePaths = restoreWritablePaths;
    services.homelab.backupRunner.readablePaths = backupReadablePaths;
  };
}