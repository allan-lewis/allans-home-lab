{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.managedDirectories;

  # Python with PyYAML available (so `import yaml` works).
  py = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);

  rehydrateScript = pkgs.writeShellScript "homelab-managed-dirs-rehydrate" ''
    set -Eeuo pipefail

    CONFIG=${lib.escapeShellArg cfg.configPath}

    HOME_DIR="''${HOME:-/tmp}"
    LOGFILE="$HOME_DIR/rehydrate.log"
    KNOWN_HOSTS="$HOME_DIR/known_hosts"

    mkdir -p "$HOME_DIR"
    touch "$LOGFILE"
    chmod 0644 "$LOGFILE"

    # known_hosts must be writable by the service user; HOME is our StateDirectory path.
    touch "$KNOWN_HOSTS"
    chmod 0600 "$KNOWN_HOSTS"

    exec > >(tee -a "$LOGFILE") 2>&1

    timestamp() { date +"%Y-%m-%d %H:%M:%S%z"; }
    log() { echo "$(timestamp) | $*"; }
    die() { log "FATAL  | $*"; exit 1; }

    on_err() {
      rc=$?
      log "FATAL  | rehydrate failed (exit=$rc)"
      exit "$rc"
    }
    trap on_err ERR

    [[ -f "$CONFIG" ]] || die "Config missing: $CONFIG"

    # ---- YAML -> JSON (fail hard on any parse error) ----
    cfg_json="$(${py}/bin/python3 - "$CONFIG" <<'PY'
import sys, json
import yaml

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f)

if data is None:
    data = {}

md = data.get("managed_directories")
if md is None:
    md = []
data["managed_directories"] = md

print(json.dumps(data))
PY
    )"

    [[ -n "$cfg_json" ]] || die "Parsed config JSON is empty (unexpected)"

    count="$(${py}/bin/python3 -c 'import json,sys; d=json.loads(sys.argv[1]); print(len(d.get("managed_directories") or []))' "$cfg_json")"
    [[ "$count" =~ ^[0-9]+$ ]] || die "Invalid managed_directories count: '$count'"

    log "===== Managed dirs rehydrate started | entries=$count ====="

    if [[ "$count" -eq 0 ]]; then
      log "INFO   | No managed_directories; nothing to do."
      log "===== Managed dirs rehydrate finished (OK) ====="
      exit 0
    fi

    # --------------------------------------------------------------------
    # IMPORTANT: rsync-over-ssh requires ssh stdin/stdout for protocol.
    # DO NOT use: ssh -n, -o StdinNull=yes, or stdin redirection for rsync.
    # --------------------------------------------------------------------

    # Safe for probes (does not carry rsync protocol)
    ssh_cmd_probe() {
      ${pkgs.openssh}/bin/ssh \
        -n \
        -i ${lib.escapeShellArg cfg.sshIdentityPath} \
        -o IdentitiesOnly=yes \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=accept-new \
        -o UserKnownHostsFile="$KNOWN_HOSTS" \
        -o ConnectTimeout=10 \
        "$@"
    }

    # Used by rsync transport (MUST allow stdin/stdout to pass through)
    ssh_cmd_rsync() {
      ${pkgs.openssh}/bin/ssh \
        -i ${lib.escapeShellArg cfg.sshIdentityPath} \
        -o IdentitiesOnly=yes \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=accept-new \
        -o UserKnownHostsFile="$KNOWN_HOSTS" \
        -o ConnectTimeout=10 \
        "$@"
    }

    remote_exists() {
      local remote="$1"
      local hostpart pathpart

      [[ "$remote" == *:* ]] || return 2
      hostpart="''${remote%%:*}"
      pathpart="''${remote#*:}"
      [[ -n "$pathpart" ]] || return 2

      ssh_cmd_probe "$hostpart" "test -d '$pathpart'"
    }

    do_rsync_restore() {
      local remote="$1"
      local local_dir="$2"

      local remote_norm="''${remote%/}/"
      local local_norm="''${local_dir%/}/"

      # NOTE: use ssh_cmd_rsync here; do NOT include -n / StdinNull.
      ${pkgs.rsync}/bin/rsync \
        ${lib.concatStringsSep " " (map lib.escapeShellArg cfg.rsyncFlags)} \
        -e "${pkgs.openssh}/bin/ssh -i ${lib.escapeShellArg cfg.sshIdentityPath} -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$KNOWN_HOSTS -o ConnectTimeout=10" \
        --progress \
        "$remote_norm" "$local_norm"
    }

    # ---- Build a robust loop list (no TSV, no NUL, no IFS surprises) ----
    mapfile -t entries_b64 < <(${py}/bin/python3 - "$cfg_json" <<'PY'
import sys, json, base64
data = json.loads(sys.argv[1])
items = data.get("managed_directories") or []

for i, d in enumerate(items):
    out = {
        "name": d.get("name", f"dir_{i}"),
        "local": d.get("local", ""),
        "remote": d.get("remote", ""),
        "owner": d.get("owner", "root"),
        "group": d.get("group", d.get("owner", "root")),
        "marker": d.get("marker", ".restored_from_backup"),
        "restore": bool(d.get("restore", True)),
        "restore_when": d.get("restore_when", "empty_and_marker_missing"),
    }
    print(base64.b64encode(json.dumps(out).encode("utf-8")).decode("ascii"))
PY
    )

    failures=0
    restored=0

    for b64 in "''${entries_b64[@]}"; do
      entry_json="$(printf '%s' "$b64" | ${pkgs.coreutils}/bin/base64 -d)"

      fields="$(${py}/bin/python3 - "$entry_json" <<'PY'
import sys, json
d = json.loads(sys.argv[1])
def s(x): return "" if x is None else str(x)
vals = [
  s(d.get("name","")),
  s(d.get("local","")),
  s(d.get("remote","")),
  s(d.get("owner","root")),
  s(d.get("group", d.get("owner","root"))),
  s(d.get("marker",".restored_from_backup")),
  "true" if bool(d.get("restore", True)) else "false",
  s(d.get("restore_when","empty_and_marker_missing")),
]
print("\t".join(vals), end="")
PY
      )"

      IFS=$'\t' read -r name local remote owner group marker restore restore_when <<< "$fields"
      [[ -z "$name" ]] && name="UNKNOWN"

      if [[ "$restore" != "true" ]]; then
        log "SKIP   | name=$name | restore=false"
        continue
      fi

      if [[ "$restore_when" != "empty_and_marker_missing" ]]; then
        log "FATAL  | name=$name | unsupported restore_when='$restore_when'"
        failures=$((failures+1))
        continue
      fi

      if [[ -z "$local" || "$local" != /* || "$local" == "/" ]]; then
        log "FATAL  | name=$name | invalid local path: '$local'"
        failures=$((failures+1))
        continue
      fi

      marker_path="$local/$marker"

      if [[ ! -d "$local" ]]; then
        log "FATAL  | name=$name | local dir missing (expected Nix tmpfiles): $local"
        failures=$((failures+1))
        continue
      fi

      if [[ -e "$marker_path" ]]; then
        log "OK     | name=$name | marker present; hydrated"
        continue
      fi

      if [[ -n "$(ls -A "$local" 2>/dev/null || true)" ]]; then
        log "FATAL  | name=$name | non-empty but marker missing; refusing: $local"
        failures=$((failures+1))
        continue
      fi

      if [[ -z "$remote" ]]; then
        log "FATAL  | name=$name | restore enabled but remote empty"
        failures=$((failures+1))
        continue
      fi

      log "CHECK  | name=$name | remote exists? $remote"
      if ! remote_exists "$remote"; then
        rc=$?
        if [[ "$rc" -eq 2 ]]; then
          log "FATAL  | name=$name | invalid remote (expected user@host:/path): '$remote'"
        else
          log "FATAL  | name=$name | remote missing/unreachable: '$remote'"
        fi
        failures=$((failures+1))
        continue
      fi

      log "START  | name=$name | restore '$remote' -> '$local'"
      if do_rsync_restore "$remote" "$local"; then
        log "CHOWN  | name=$name | chown -R $owner:$group '$local'"
        ${pkgs.coreutils}/bin/chown -R "$owner:$group" "$local"

        log "MARK   | name=$name | write marker: $marker_path"
        tmp="$(mktemp "$local/.marker.XXXXXX")"
        printf '%s\n' "$(timestamp) restored from $remote" > "$tmp"
        ${pkgs.coreutils}/bin/chown "$owner:$group" "$tmp"
        ${pkgs.coreutils}/bin/chmod 0644 "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$marker_path"

        if [[ -e "$marker_path" && -n "$(ls -A "$local" 2>/dev/null || true)" ]]; then
          log "OK     | name=$name | restored + marked"
          restored=$((restored+1))
        else
          log "FATAL  | name=$name | post-check failed (marker/contents)"
          failures=$((failures+1))
        fi
      else
        log "FATAL  | name=$name | rsync failed"
        failures=$((failures+1))
      fi
    done

    if [[ "$failures" -eq 0 ]]; then
      log "===== Managed dirs rehydrate finished (OK) | restored=$restored ====="
      exit 0
    else
      log "===== Managed dirs rehydrate finished (FAIL) | failures=$failures restored=$restored ====="
      exit 1
    fi
  '';

  # Proper package w/ /bin/rehydrate-managed-dirs (merges into system-path cleanly)
  rehydrateGate = pkgs.writeScriptBin "rehydrate-managed-dirs" ''
    #!${py}/bin/python3
    import os
    import sys
    import subprocess
    from typing import Any, Dict, List

    import yaml

    DEFAULT_MARKER = ".restored_from_backup"
    DEFAULT_LOG = "/var/log/rehydrate-managed-dirs.log"
    DEFAULT_CONFIG = ${builtins.toJSON cfg.configPath}
    SYSTEMCTL = ${builtins.toJSON "${pkgs.systemd}/bin/systemctl"}


    def _append_log(line: str) -> None:
        try:
            with open(DEFAULT_LOG, "a", encoding="utf-8") as f:
                f.write(line + "\n")
        except Exception:
            pass


    def log(msg: str) -> None:
        line = f"INFO  | {msg}"
        print(line)
        _append_log(line)


    def err(msg: str) -> None:
        line = f"ERROR | {msg}"
        print(line, file=sys.stderr)
        _append_log(line)


    def die(msg: str, code: int = 1) -> None:
        err(f"FATAL | {msg}")
        sys.exit(code)


    def run(cmd: List[str]) -> subprocess.CompletedProcess:
        return subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


    def load_yaml(path: str) -> Dict[str, Any]:
        if not os.path.exists(path):
            die(f"Config missing: {path}")
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = yaml.safe_load(f)
            if data is None:
                data = {}
            if not isinstance(data, dict):
                die(f"Config root must be a dict: {path}")
            return data
        except Exception as ex:
            die(f"Failed to parse YAML '{path}': {ex}")


    def norm_bool(v: Any) -> bool:
        if isinstance(v, bool):
            return v
        if isinstance(v, str):
            return v.strip().lower() in ("1", "true", "yes", "on")
        return bool(v)


    def listdir_safe(path: str) -> List[str]:
        try:
            return os.listdir(path)
        except Exception:
            return []


    def main() -> int:
        # Usage: rehydrate-managed-dirs <unit> [config_path]
        unit = (sys.argv[1].strip() if len(sys.argv) >= 2 else "")
        config_path = (sys.argv[2] if len(sys.argv) >= 3 else os.environ.get("MANAGED_DIRS_CONFIG", DEFAULT_CONFIG))
        require_nonempty = os.environ.get("MANAGED_DIRS_REQUIRE_NONEMPTY", "1").strip().lower() not in ("0", "false", "no", "off")

        if not unit:
            die("Unit name required: rehydrate-managed-dirs <unit> [config_path]")

        log(f"===== managed-dirs gate start | unit={unit} config={config_path} require_nonempty={str(require_nonempty).lower()} =====")

        cfg = load_yaml(config_path)

        ver = cfg.get("version", 0)
        try:
            if int(ver) != 1:
                die(f"Unsupported config version: {ver} (expected 1)")
        except Exception:
            die(f"Invalid version value: {ver} (expected int)")

        managed = cfg.get("managed_directories", [])
        if managed is None:
            managed = []
        if not isinstance(managed, list):
            die("managed_directories must be a list")

        # Only enforce entries where restore==true AND remote is non-empty.
        selected: List[Dict[str, Any]] = []
        for i, d in enumerate(managed):
            if not isinstance(d, dict):
                die(f"managed_directories[{i}] must be a dict")
            restore = norm_bool(d.get("restore", False))
            remote = str(d.get("remote") or "").strip()
            if restore and remote:
                selected.append(d)

        log(f"loaded={len(managed)} selected={len(selected)} (restore=true && remote!=empty)")

        p = run([SYSTEMCTL, "start", unit])
        if p.returncode != 0:
            die(f"systemctl start {unit} failed (rc={p.returncode}):\n{p.stdout}")

        failures = 0
        for i, d in enumerate(selected):
            name = str(d.get("name") or f"dir_{i}")
            local = str(d.get("local") or "").strip()
            marker = str(d.get("marker") or DEFAULT_MARKER).strip() or DEFAULT_MARKER

            if (not local) or (not local.startswith("/")) or (local == "/"):
                err(f"name={name} invalid local='{local}'")
                failures += 1
                continue

            if not os.path.isdir(local):
                err(f"name={name} local missing/not dir: {local}")
                failures += 1
                continue

            marker_path = os.path.join(local.rstrip("/"), marker)
            if not os.path.exists(marker_path):
                err(f"name={name} marker missing: {marker_path}")
                failures += 1
                continue

            if require_nonempty:
                entries = [x for x in listdir_safe(local) if x not in (".", "..") and x != marker]
                if len(entries) == 0:
                    err(f"name={name} dir empty (excluding marker): {local}")
                    failures += 1
                    continue

            log(f"OK name={name} hydrated local={local} marker={marker_path}")

        if failures:
            die(f"managed-dirs gate failed | failures={failures}", code=2)

        log("===== managed-dirs gate finished (OK) =====")
        return 0


    if __name__ == "__main__":
        try:
            sys.exit(main())
        except KeyboardInterrupt:
            die("Interrupted", code=130)
  '';
in
{
  options.services.homelab.managedDirectories = {
    enable = lib.mkEnableOption "Managed directories (rehydrate oneshot task)";

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/allans-home-lab/managed-directories/config.yaml";
      description = "Canonical config written by Ansible.";
    };

    sshIdentityPath = lib.mkOption {
      type = lib.types.str;
      default = "/root/.ssh/id_ed25519";
      description = "SSH identity used for remote restore.";
    };

    rsyncFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "-aHAX" "--numeric-ids" ];
    };

    writablePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Allowlisted managed local directories the rehydrate task may write into (ReadWritePaths).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.writablePaths != [];
        message = "services.homelab.managedDirectories.writablePaths must be set (task hardening requires explicit write allowlist).";
      }
    ];

    services.homelab.tasks.enable = lib.mkDefault true;

    systemd.tmpfiles.rules = [
      "d /etc/allans-home-lab/managed-directories 0755 root root -"
    ];

    # Provides: /run/current-system/sw/bin/rehydrate-managed-dirs
    environment.systemPackages = [ rehydrateGate ];

    services.homelab.tasks.tasks."managed-dirs-rehydrate" = {
      description = "Managed directories rehydrate (restore if empty + marker missing; fail-closed)";
      command = [ "${rehydrateScript}" ];

      schedule = null;
      persistent = false;
      timeoutSec = 3600;

      requiresNetworkOnline = true;

      stateDirectory = "homelab-managed-dirs";
      environment = { HOME = "/var/lib/homelab-managed-dirs"; };

      protectHome = "read-only";
      readOnlyPaths = [ "/root/.ssh" cfg.configPath ];

      readWritePaths = cfg.writablePaths;

      path = [
        pkgs.rsync
        pkgs.openssh
        pkgs.coreutils
        py
      ];

      taskLabel = "managed_dirs_rehydrate";
    };
  };
}
