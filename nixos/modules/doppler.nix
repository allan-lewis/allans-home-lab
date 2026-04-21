{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.doppler;

  esc = lib.escapeShellArg;
in
{
  options.services.homelab.doppler = {
    enable = lib.mkEnableOption "Doppler CLI scoped configuration";

    user = lib.mkOption {
      type = lib.types.str;
      default = "lab";
      description = "User to run doppler setup as.";
    };

    scopeDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/lab/src";
      description = "Directory scope for doppler configuration.";
    };

    tokenFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a durable doppler service token file.

        IMPORTANT: this must NOT be in /nix/store. Write it earlier in your converge process
        (e.g. /var/lib/homelab-secrets/doppler/doppler_token) with appropriate permissions.
      '';
    };

    project = lib.mkOption {
      type = lib.types.str;
      description = "Doppler project name.";
    };

    dopplerConfig = lib.mkOption {
      type = lib.types.str;
      description = "Doppler config name (e.g. dev, prod).";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.doppler ];

    # Ensure scope directory exists
    systemd.tmpfiles.rules = [
      "d ${cfg.scopeDir} 0755 ${cfg.user} ${cfg.user} - -"
    ];

    sops.secrets.doppler_token = {
      sopsFile = ../secrets/doppler.yaml;
      key = "doppler_token";
      path = "/var/lib/homelab-secrets/doppler/doppler_token";
      owner = "lab";
      group = "lab";
      mode = "0600";
    };

    systemd.services.homelab-doppler-setup = {
      description = "Homelab: configure Doppler for scoped directory";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        WorkingDirectory = cfg.scopeDir;

        # Make failures visible in journald
        StandardOutput = "journal";
        StandardError = "journal";
      };

      script = ''
        set -euo pipefail

        TOKEN_FILE=${esc (toString cfg.tokenFile)}
        SCOPE=${esc cfg.scopeDir}

        # Refuse to proceed if tokenFile points into the Nix store
        case "$TOKEN_FILE" in
          /nix/store/*)
            echo "ERROR: services.homelab.doppler.tokenFile must not be in /nix/store: $TOKEN_FILE" >&2
            exit 2
            ;;
        esac

        # If token missing/empty, skip (mirrors your Ansible gating behavior)
        if [[ ! -s "$TOKEN_FILE" ]]; then
          echo "doppler token missing/empty at $TOKEN_FILE; skipping"
          exit 0
        fi

        token="$(cat "$TOKEN_FILE")"
        if [[ -z "$token" ]]; then
          echo "doppler token empty; skipping"
          exit 0
        fi

        # Ensure scope exists (tmpfiles should handle this, but keep it robust)
        mkdir -p "$SCOPE"

        # Set token for this scope (stdin is safest)
        printf %s "$token" | ${pkgs.doppler}/bin/doppler configure set token --scope "$SCOPE"

        # Configure project/config for this scope
        ${pkgs.doppler}/bin/doppler setup \
          --project ${esc cfg.project} \
          --config ${esc cfg.dopplerConfig} \
          --scope "$SCOPE" \
          --no-interactive
      '';
    };
  };
}