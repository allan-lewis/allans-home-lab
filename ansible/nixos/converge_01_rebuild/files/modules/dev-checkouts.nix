{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.devCheckouts;

  # Allow: letters, digits, underscore, dash, dot
  nameRegex = "^[A-Za-z0-9_.-]+$";

  esc = lib.escapeShellArg;

  repoCalls =
    lib.concatStringsSep "\n"
      (map (r: ''
        sync_repo ${esc r.repo} ${esc r.dest} ${esc (r.version or "main")}
      '') cfg.repos);

  # IMPORTANT:
  # - This script will be executed as cfg.user (via runuser below),
  #   so any created/updated dirs will be owned by cfg.user.
  syncScript = pkgs.writeShellScript "homelab-dev-checkouts-sync" ''
    set -euo pipefail

    ROOT=${esc cfg.rootDir}
    RUN_USER=${esc cfg.user}

    # Ensure git/ssh behave like the target user even when started from a root-run unit.
    export HOME="/home/$RUN_USER"
    export USER="$RUN_USER"
    export LOGNAME="$RUN_USER"

    # Non-interactive SSH; accept-new host keys (similar intent to Ansible accept_hostkey).
    export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new"

    log() { printf '%s\n' "$*"; }
    err() { printf '%s\n' "$*" >&2; }

    # Exit code policy:
    # - 0: ran successfully (including skips for local state)
    # - 2: operational errors
    errors=0
    updated=0
    ok=0
    skipped_dirty=0
    skipped_ahead=0
    skipped_diverged=0
    skipped_wrong_branch=0

    mkdir -p "$ROOT" || { err "ERROR | mkdir failed: $ROOT"; exit 2; }

    sync_repo() {
      local url="$1"
      local dest="$2"
      local branch="$3"
      local dir="$ROOT/$dest"

      if [[ ! -e "$dir" ]]; then
        log "CLONE  | repo=$dest branch=$branch"
        if ! git clone --branch "$branch" "$url" "$dir"; then
          err "ERROR | clone failed | repo=$dest"
          errors=$((errors+1))
        fi
        return 0
      fi

      if [[ ! -d "$dir/.git" ]]; then
        err "ERROR | not a git repo | repo=$dest path=$dir"
        errors=$((errors+1))
        return 0
      fi

      # Untracked counts as dirty (your requirement)
      if [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
        log "SKIP   | dirty (untracked counts) | repo=$dest path=$dir"
        skipped_dirty=$((skipped_dirty+1))
        return 0
      fi

      current_branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
      if [[ -z "$current_branch" ]]; then
        err "ERROR | cannot read current branch | repo=$dest path=$dir"
        errors=$((errors+1))
        return 0
      fi

      if [[ "$current_branch" != "$branch" ]]; then
        log "SKIP   | wrong branch | repo=$dest current=$current_branch expected=$branch"
        skipped_wrong_branch=$((skipped_wrong_branch+1))
        return 0
      fi

      log "FETCH  | repo=$dest"
      if ! git -C "$dir" fetch --prune --tags origin; then
        err "ERROR | fetch failed | repo=$dest"
        errors=$((errors+1))
        return 0
      fi

      if ! git -C "$dir" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        err "ERROR | missing origin/$branch after fetch | repo=$dest"
        errors=$((errors+1))
        return 0
      fi

      ahead="$(git -C "$dir" rev-list --count "origin/$branch..$branch" 2>/dev/null || echo 0)"
      behind="$(git -C "$dir" rev-list --count "$branch..origin/$branch" 2>/dev/null || echo 0)"

      if [[ "$ahead" != "0" && "$behind" != "0" ]]; then
        log "SKIP   | diverged | repo=$dest ahead=$ahead behind=$behind"
        skipped_diverged=$((skipped_diverged+1))
        return 0
      fi

      if [[ "$ahead" != "0" && "$behind" == "0" ]]; then
        log "SKIP   | ahead (local commits present) | repo=$dest ahead=$ahead"
        skipped_ahead=$((skipped_ahead+1))
        return 0
      fi

      if [[ "$ahead" == "0" && "$behind" != "0" ]]; then
        log "UPDATE | ff-only pull | repo=$dest behind=$behind"
        if git -C "$dir" pull --ff-only origin "$branch"; then
          updated=$((updated+1))
        else
          err "ERROR | pull --ff-only failed | repo=$dest"
          errors=$((errors+1))
        fi
        return 0
      fi

      log "OK     | up-to-date | repo=$dest"
      ok=$((ok+1))
    }

    ${repoCalls}

    log "SUMMARY| ok=$ok updated=$updated skipped_dirty=$skipped_dirty skipped_ahead=$skipped_ahead skipped_diverged=$skipped_diverged skipped_wrong_branch=$skipped_wrong_branch errors=$errors"

    if [[ "$errors" -gt 0 ]]; then
      exit 2
    fi
    exit 0
  '';
in
{
  options.services.homelab.devCheckouts = {
    enable = lib.mkEnableOption "Homelab dev checkouts (mutable git working dirs)";

    user = lib.mkOption {
      type = lib.types.str;
      default = "lab";
      description = "User account that owns and runs the dev checkouts task.";
    };

    rootDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/lab/src";
      description = "Root directory where git working directories live.";
    };

    schedule = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "hourly";
      description = "systemd OnCalendar value for the sync task. Null disables the timer (manual runs only).";
    };

    repos = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          repo = lib.mkOption {
            type = lib.types.str;
            description = "Git URL (e.g., git@github.com:org/repo.git).";
          };
          dest = lib.mkOption {
            type = lib.types.str;
            description = "Destination directory name under rootDir.";
          };
          version = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = "main";
            description = "Branch name to clone and track (e.g., main).";
          };
        };
      });
      default = [];
      description = "Repositories to ensure exist as writable working directories.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.repos != [];
        message = "services.homelab.devCheckouts.enable is true but repos is empty.";
      }
      {
        assertion = lib.all (r: (builtins.match nameRegex r.dest) != null) cfg.repos;
        message = "services.homelab.devCheckouts: each repos[].dest must match ${nameRegex}";
      }
    ];

    # Ensure the task framework is on (so this module only declares tasks)
    services.homelab.tasks.enable = lib.mkDefault true;

    # Ensure the root directory exists and is owned by the user
    # (group set to the username, which is the common NixOS pattern; adjust if your lab group differs)
    systemd.tmpfiles.rules = [
      "d ${cfg.rootDir} 0755 ${cfg.user} ${cfg.user} - -"
    ];

    services.homelab.tasks.tasks.dev_checkouts_sync = {
      enable = true;
      description = "Dev checkouts sync (clone if missing; ff-only pull if clean+behind; skip on local state)";

      # Run the sync script as cfg.user so newly created repos are owned by cfg.user.
      # Unit still runs as root (task framework), but git operations run as the user.
      command = [
        "${pkgs.util-linux}/bin/runuser"
        "-u" cfg.user
        "--"
        "${syncScript}"
      ];

      schedule = cfg.schedule;
      persistent = true;

      timeoutSec = 3600;

      workingDirectory = cfg.rootDir;

      requiresNetworkOnline = true;

      requiresMountsFor = [ "/home/${cfg.user}" cfg.rootDir ];

      # Provide git + ssh + basics + runuser
      path = [ pkgs.git pkgs.openssh pkgs.coreutils pkgs.gawk pkgs.util-linux ];

      # IMPORTANT with your hardening defaults:
      protectHome = "no";
      readWritePaths = [ cfg.rootDir ];

      # Helpful even though the script forces HOME/USER/LOGNAME
      environment = {
        HOME = "/home/${cfg.user}";
      };
    };
  };
}