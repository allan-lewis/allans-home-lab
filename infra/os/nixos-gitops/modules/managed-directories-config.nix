{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
    mapAttrsToList
    filter
    concatMapStringsSep;

  cfg = config.homelab.managedDirectories;

  markerFile = ".restored_from_backup";

  entriesList =
    mapAttrsToList
      (name: d:
        {
          inherit name;

          local = d.local;
          remote = d.remote;
          owner = d.owner;
          group = d.group;
          mode = d.mode;
          backup = d.backup;
          restore = d.restore;
        })
      cfg.entries;

  yamlBool = b: if b then "true" else "false";

  managedDirectoriesYaml = pkgs.writeText "managed-directories.yaml" (
    ''
      version: 2
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
            marker: "${markerFile}"
        '') entriesList
    )
  );

  backupReadablePaths =
    map (d: d.local) (filter (d: d.backup) entriesList);

  restoreWritablePaths =
    map (d: d.local) (filter (d: d.restore) entriesList);

in
{
  options.homelab.managedDirectories = {
    entries = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options = {
          local = mkOption {
            type = types.str;
            description = "Absolute local path for the managed directory.";
          };

          remote = mkOption {
            type = types.str;
            description = "Remote rsync target/source in user@host:/path form.";
          };

          owner = mkOption {
            type = types.str;
            default = "root";
            description = "Owner to enforce after restore.";
          };

          group = mkOption {
            type = types.str;
            default = "root";
            description = "Group to enforce after restore.";
          };

          mode = mkOption {
            type = types.str;
            default = "0755";
            description = "Directory mode for documentation/config consistency.";
          };

          backup = mkOption {
            type = types.bool;
            default = true;
            description = "Whether this directory participates in backup operations.";
          };

          restore = mkOption {
            type = types.bool;
            default = true;
            description = "Whether this directory participates in restore operations.";
          };
        };
      }));
      default = {};
      description = "Managed directories keyed by logical name.";
    };
  };

  config = {
    environment.etc."allans-home-lab/managed-directories/config.yaml".source =
      managedDirectoriesYaml;

    services.homelab.managedState.writablePaths = restoreWritablePaths;
    services.homelab.managedState.readablePaths = backupReadablePaths;
  };
}