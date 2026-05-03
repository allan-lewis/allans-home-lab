{ lib, pkgs, config, ... }:

let
  cfg = config.services.homelab.managedState;

  py = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);

  runner = pkgs.writeScriptBin "managed-state-runner" ''
    #!${py}/bin/python3
    import os
    import sys
    import yaml
    import json
    import fcntl
    import subprocess
    from datetime import datetime
    from typing import Any, Dict, List, Tuple


    MARKER = ".restored_from_backup"
    DEFAULT_CONFIG = ${builtins.toJSON cfg.configPath}
    DEFAULT_SSH_IDENTITY = ${builtins.toJSON cfg.sshIdentityPath}
    DEFAULT_LOGFILE = "managed-state.log"
    DEFAULT_LOCKFILE = "managed-state.lock"
    RSYNC_RESTORE_FLAGS = ${builtins.toJSON cfg.restoreRsyncFlags}
    RSYNC_BACKUP_FLAGS = ${builtins.toJSON cfg.backupRsyncFlags}


    def timestamp() -> str:
        return datetime.now().astimezone().strftime("%Y-%m-%d %H:%M:%S%z")


    def home_dir() -> str:
        return os.environ.get("HOME", "/tmp")


    def logfile_path() -> str:
        return os.path.join(home_dir(), DEFAULT_LOGFILE)


    def lockfile_path() -> str:
        return os.path.join(home_dir(), DEFAULT_LOCKFILE)


    def known_hosts_path() -> str:
        return os.path.join(home_dir(), "known_hosts")


    def ensure_runtime_paths() -> None:
        os.makedirs(home_dir(), exist_ok=True)
        with open(logfile_path(), "a", encoding="utf-8"):
            pass
        try:
            os.chmod(logfile_path(), 0o644)
        except Exception:
            pass

        with open(known_hosts_path(), "a", encoding="utf-8"):
            pass
        try:
            os.chmod(known_hosts_path(), 0o600)
        except Exception:
            pass


    def _append_log(line: str) -> None:
        try:
            with open(logfile_path(), "a", encoding="utf-8") as f:
                f.write(line + "\n")
        except Exception:
            pass


    def log(level: str, msg: str) -> None:
        line = f"{timestamp()} | {level:<6} | {msg}"
        print(line, flush=True)
        _append_log(line)


    def die(msg: str, code: int = 1) -> None:
        log("FATAL", msg)
        sys.exit(code)


    def run(cmd: List[str]) -> subprocess.CompletedProcess:
        return subprocess.run(cmd, text=True)


    def run_capture(cmd: List[str]) -> subprocess.CompletedProcess:
        return subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


    def load_yaml(path: str) -> Dict[str, Any]:
        if not os.path.exists(path):
            die(f"Config missing: {path}")

        try:
            with open(path, "r", encoding="utf-8") as f:
                data = yaml.safe_load(f)
        except Exception as ex:
            die(f"Failed to parse YAML '{path}': {ex}")

        if data is None:
            data = {}

        if not isinstance(data, dict):
            die(f"Config root must be a dict: {path}")

        return data


    def parse_bool(v: Any, default: bool) -> bool:
        if v is None:
            return default
        if isinstance(v, bool):
            return v
        if isinstance(v, str):
            return v.strip().lower() in ("1", "true", "yes", "on")
        return bool(v)


    def listdir_safe(path: str) -> List[str]:
        try:
            return [x for x in os.listdir(path) if x not in (".", "..")]
        except Exception:
            return []


    def non_marker_entries(path: str) -> List[str]:
        return [x for x in listdir_safe(path) if x != MARKER]


    def validate_remote(remote: str) -> bool:
        return ":" in remote and remote.split(":", 1)[1].strip() != ""


    def split_remote(remote: str) -> Tuple[str, str]:
        host, path = remote.split(":", 1)
        return host, path


    def ssh_base_args() -> List[str]:
        return [
            "${pkgs.openssh}/bin/ssh",
            "-i", DEFAULT_SSH_IDENTITY,
            "-o", "IdentitiesOnly=yes",
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=accept-new",
            "-o", f"UserKnownHostsFile={known_hosts_path()}",
            "-o", "ConnectTimeout=10",
            "-o", "ServerAliveInterval=10",
            "-o", "ServerAliveCountMax=3",
        ]


    def ssh_probe_args() -> List[str]:
        return ssh_base_args() + ["-n"]


    def remote_exists(remote: str) -> Tuple[bool, str]:
        if not validate_remote(remote):
            return False, "invalid"

        host, path = split_remote(remote)
        p = run(ssh_probe_args() + [host, f"test -d '{path}'"])
        return (p.returncode == 0), "ok" if p.returncode == 0 else "missing"


    def rsync_ssh_cmd() -> str:
        return " ".join([
            "${pkgs.openssh}/bin/ssh",
            "-i", DEFAULT_SSH_IDENTITY,
            "-o", "IdentitiesOnly=yes",
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=accept-new",
            "-o", f"UserKnownHostsFile={known_hosts_path()}",
            "-o", "ConnectTimeout=10",
            "-o", "ServerAliveInterval=10",
            "-o", "ServerAliveCountMax=3",
        ])


    def rsync_restore(remote: str, local_dir: str) -> bool:
        remote_norm = remote.rstrip("/") + "/"
        local_norm = local_dir.rstrip("/") + "/"

        cmd = [
            "${pkgs.rsync}/bin/rsync",
            *RSYNC_RESTORE_FLAGS,
            "--exclude", MARKER,
            "-e", rsync_ssh_cmd(),
            "--progress",
            remote_norm,
            local_norm,
        ]
        return run(cmd).returncode == 0


    def rsync_backup(local_dir: str, remote: str) -> bool:
        src_norm = local_dir.rstrip("/") + "/"
        dest_norm = remote.rstrip("/") + "/"

        cmd = [
            "${pkgs.rsync}/bin/rsync",
            *RSYNC_BACKUP_FLAGS,
            "--exclude", MARKER,
            "-e", rsync_ssh_cmd(),
            "--progress",
            src_norm,
            dest_norm,
        ]
        return run(cmd).returncode == 0


    def write_marker(local_dir: str, owner: str, group: str, remote: str) -> bool:
        marker_path = os.path.join(local_dir.rstrip("/"), MARKER)
        tmp_path = os.path.join(local_dir.rstrip("/"), f".marker.tmp.{os.getpid()}")

        try:
            with open(tmp_path, "w", encoding="utf-8") as f:
                f.write(f"{timestamp()} restored from {remote}\n")

            run(["${pkgs.coreutils}/bin/chown", f"{owner}:{group}", tmp_path])
            run(["${pkgs.coreutils}/bin/chmod", "0644", tmp_path])
            os.replace(tmp_path, marker_path)
            return True
        except Exception as ex:
            log("ERROR", f"marker write failed path={marker_path} error={ex}")
            try:
                if os.path.exists(tmp_path):
                    os.unlink(tmp_path)
            except Exception:
                pass
            return False


    def chown_tree(local_dir: str, owner: str, group: str) -> bool:
        return run(["${pkgs.coreutils}/bin/chown", "-R", f"{owner}:{group}", local_dir]).returncode == 0


    def load_entries(config_path: str) -> List[Dict[str, Any]]:
        cfg = load_yaml(config_path)

        version = cfg.get("version")
        try:
            if int(version) != 2:
                die(f"Unsupported config version: {version} (expected 2)")
        except Exception:
            die(f"Invalid config version: {version} (expected 2)")

        managed = cfg.get("managed_directories", [])
        if managed is None:
            managed = []

        if not isinstance(managed, list):
            die("managed_directories must be a list")

        out: List[Dict[str, Any]] = []
        for i, raw in enumerate(managed):
            if not isinstance(raw, dict):
                die(f"managed_directories[{i}] must be a dict")

            entry = {
                "name": str(raw.get("name") or f"dir_{i}"),
                "local": str(raw.get("local") or "").strip(),
                "remote": str(raw.get("remote") or "").strip(),
                "owner": str(raw.get("owner") or "root"),
                "group": str(raw.get("group") or "root"),
                "mode": str(raw.get("mode") or "0755"),
                "backup": parse_bool(raw.get("backup"), True),
                "restore": parse_bool(raw.get("restore"), True),
                "marker": str(raw.get("marker") or MARKER).strip() or MARKER,
            }

            if entry["marker"] != MARKER:
                die(f"name={entry['name']} unsupported marker='{entry['marker']}' expected='{MARKER}'")

            out.append(entry)

        return out


    def classify_restore_need(entry: Dict[str, Any]) -> Tuple[str, str]:
        name = entry["name"]
        local_dir = entry["local"]

        if not entry["restore"]:
            return "skip", f"name={name} restore=false"

        if not local_dir or not local_dir.startswith("/") or local_dir == "/":
            return "error", f"name={name} invalid local path: '{local_dir}'"

        if not os.path.isdir(local_dir):
            return "error", f"name={name} local dir missing/not dir: {local_dir}"

        marker_path = os.path.join(local_dir.rstrip("/"), MARKER)
        if os.path.exists(marker_path):
            return "ok", f"name={name} marker present; hydrated"

        remaining = non_marker_entries(local_dir)
        if len(remaining) > 0:
            return "error", f"name={name} marker missing but dir non-empty; refusing: {local_dir}"

        if not entry["remote"]:
            return "error", f"name={name} restore enabled but remote empty"

        return "needs_restore", f"name={name} marker missing and dir empty; restore needed"


    def restore_entry(entry: Dict[str, Any]) -> bool:
        name = entry["name"]
        local_dir = entry["local"]
        remote = entry["remote"]
        owner = entry["owner"]
        group = entry["group"]

        if not validate_remote(remote):
            log("ERROR", f"name={name} invalid remote (expected user@host:/path): '{remote}'")
            return False

        log("CHECK", f"name={name} remote exists? {remote}")
        exists, state = remote_exists(remote)
        if not exists:
            if state == "invalid":
                log("ERROR", f"name={name} invalid remote (expected user@host:/path): '{remote}'")
            else:
                log("ERROR", f"name={name} remote missing/unreachable: '{remote}'")
            return False

        log("START", f"name={name} restore '{remote}' -> '{local_dir}'")
        if not rsync_restore(remote, local_dir):
            log("ERROR", f"name={name} rsync restore failed")
            return False

        log("CHOWN", f"name={name} chown -R {owner}:{group} '{local_dir}'")
        if not chown_tree(local_dir, owner, group):
            log("ERROR", f"name={name} chown failed")
            return False

        log("MARK", f"name={name} write marker '{local_dir}/{MARKER}'")
        if not write_marker(local_dir, owner, group, remote):
            log("ERROR", f"name={name} marker write failed")
            return False

        marker_path = os.path.join(local_dir.rstrip("/"), MARKER)
        if not os.path.exists(marker_path):
            log("ERROR", f"name={name} marker missing after restore")
            return False

        log("OK", f"name={name} restored + marked")
        return True


    def backup_entry(entry: Dict[str, Any]) -> bool:
        name = entry["name"]
        local_dir = entry["local"]
        remote = entry["remote"]

        if not entry["backup"]:
            log("SKIP", f"name={name} backup=false")
            return True

        if not local_dir or not local_dir.startswith("/") or local_dir == "/":
            log("ERROR", f"name={name} invalid local path: '{local_dir}'")
            return False

        if not os.path.isdir(local_dir):
            log("ERROR", f"name={name} local dir missing/not dir: {local_dir}")
            return False

        marker_path = os.path.join(local_dir.rstrip("/"), MARKER)
        if not os.path.exists(marker_path):
            log("ERROR", f"name={name} marker missing; refusing backup: {marker_path}")
            return False

        if not remote:
            log("ERROR", f"name={name} backup enabled but remote empty")
            return False

        if not validate_remote(remote):
            log("ERROR", f"name={name} invalid remote (expected user@host:/path): '{remote}'")
            return False

        log("CHECK", f"name={name} remote exists? {remote}")
        exists, state = remote_exists(remote)
        if not exists:
            if state == "invalid":
                log("ERROR", f"name={name} invalid remote (expected user@host:/path): '{remote}'")
            else:
                log("ERROR", f"name={name} remote missing/unreachable: '{remote}'")
            return False

        log("START", f"name={name} backup '{local_dir}/' -> '{remote}/'")
        if not rsync_backup(local_dir, remote):
            log("ERROR", f"name={name} rsync backup failed")
            return False

        log("OK", f"name={name} backup complete")
        return True


    def acquire_lock():
        f = open(lockfile_path(), "w", encoding="utf-8")
        try:
            fcntl.flock(f.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            die("another managed-state run is already in progress")
        f.write(str(os.getpid()))
        f.flush()
        return f


    def run_restore_mode(entries: List[Dict[str, Any]]) -> int:
        failures = 0
        restored = 0
        skipped = 0

        log("INFO", f"restore mode start | entries={len(entries)}")

        for entry in entries:
            state, msg = classify_restore_need(entry)

            if state == "skip":
                log("SKIP", msg)
                skipped += 1
                continue

            if state == "ok":
                log("OK", msg)
                skipped += 1
                continue

            if state == "error":
                log("ERROR", msg)
                failures += 1
                continue

            if state == "needs_restore":
                log("INFO", msg)
                if restore_entry(entry):
                    restored += 1
                else:
                    failures += 1
                continue

            log("ERROR", f"name={entry['name']} unknown restore classification: {state}")
            failures += 1

        if failures:
            log("FATAL", f"restore mode finished (FAIL) | failures={failures} restored={restored} skipped={skipped}")
            return 1

        log("INFO", f"restore mode finished (OK) | restored={restored} skipped={skipped}")
        return 0


    def run_default_mode(entries: List[Dict[str, Any]]) -> int:
        failures = 0
        restore_needed: List[Dict[str, Any]] = []

        log("INFO", f"default mode inspect start | entries={len(entries)}")

        for entry in entries:
            state, msg = classify_restore_need(entry)

            if state == "skip":
                log("SKIP", msg)
                continue

            if state == "ok":
                log("OK", msg)
                continue

            if state == "error":
                log("ERROR", msg)
                failures += 1
                continue

            if state == "needs_restore":
                log("INFO", msg)
                restore_needed.append(entry)
                continue

            log("ERROR", f"name={entry['name']} unknown restore classification: {state}")
            failures += 1

        if failures:
            log("FATAL", f"default mode inspect failed | failures={failures} restore_needed={len(restore_needed)}")
            return 1

        if len(restore_needed) > 0:
            log("INFO", f"default mode chose restore phase | restore_needed={len(restore_needed)}")
            return run_restore_mode(entries)

        log("INFO", "default mode chose backup phase | restore_needed=0")

        backup_failures = 0
        backed_up = 0
        skipped = 0

        for entry in entries:
            if not entry["backup"]:
                log("SKIP", f"name={entry['name']} backup=false")
                skipped += 1
                continue

            if backup_entry(entry):
                backed_up += 1
            else:
                backup_failures += 1

        if backup_failures:
            log("FATAL", f"default mode backup finished (FAIL) | failures={backup_failures} backed_up={backed_up} skipped={skipped}")
            return 1

        log("INFO", f"default mode backup finished (OK) | backed_up={backed_up} skipped={skipped}")
        return 0


    def main() -> int:
        ensure_runtime_paths()
        _lock = acquire_lock()

        mode = (sys.argv[1].strip().lower() if len(sys.argv) >= 2 else "default")
        config_path = os.environ.get("MANAGED_STATE_CONFIG", DEFAULT_CONFIG)

        if mode not in ("default", "restore"):
            die(f"Unsupported mode '{mode}' (expected: default|restore)")

        log("INFO", f"===== managed-state start | mode={mode} config={config_path} =====")
        entries = load_entries(config_path)

        if len(entries) == 0:
            log("INFO", "No managed_directories; nothing to do.")
            log("INFO", "===== managed-state finished (OK) =====")
            return 0

        if mode == "restore":
            rc = run_restore_mode(entries)
        else:
            rc = run_default_mode(entries)

        if rc == 0:
            log("INFO", "===== managed-state finished (OK) =====")
        else:
            log("FATAL", "===== managed-state finished (FAIL) =====")

        return rc


    if __name__ == "__main__":
        try:
            sys.exit(main())
        except KeyboardInterrupt:
            die("Interrupted", code=130)
  '';
in
{
  options.services.homelab.managedState = {
    enable = lib.mkEnableOption "Unified managed state restore/backup runner";

    schedule = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "hourly";
      description = "systemd OnCalendar schedule for normal mode.";
    };

    persistent = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run missed normal-mode executions at next boot.";
    };

    timeoutSec = lib.mkOption {
      type = lib.types.int;
      default = 21600;
      description = "Maximum runtime before systemd kills the managed-state task.";
    };

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/allans-home-lab/managed-directories/config.yaml";
      description = "Canonical managed directories config written by Nix/Ansible.";
    };

    sshIdentityPath = lib.mkOption {
      type = lib.types.str;
      default = "/root/.ssh/id_ed25519";
      description = "SSH identity used for both restore and backup.";
    };

    restoreRsyncFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "-aHAX" "--numeric-ids" ];
      description = "Rsync argv flags used during restore.";
    };

    backupRsyncFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "-aHAX" "--numeric-ids" "--delete" ];
      description = "Rsync argv flags used during backup.";
    };

    readablePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Allowlisted local paths the task may read.";
    };

    writablePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Allowlisted local paths the task may write during restore.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.schedule != null;
        message = "services.homelab.managedState.schedule must be set when enable = true";
      }
    ];

    services.homelab.tasks.enable = lib.mkDefault true;

    environment.systemPackages = [ runner ];

    services.homelab.tasks.tasks."managed-state" = {
      description = "Managed state runner (default mode: restore if needed, otherwise backup)";
      command = [ "${runner}/bin/managed-state-runner" ];

      schedule = cfg.schedule;
      persistent = cfg.persistent;
      timeoutSec = cfg.timeoutSec;

      requiresNetworkOnline = true;

      stateDirectory = "homelab-managed-state";
      environment = {
        HOME = "/var/lib/homelab-managed-state";
        MANAGED_STATE_CONFIG = cfg.configPath;
      };

      protectHome = "no";
      readOnlyPaths = [ "/root/.ssh" cfg.configPath ];
      readWritePaths = lib.unique (cfg.readablePaths ++ cfg.writablePaths);

      path = [
        pkgs.rsync
        pkgs.openssh
        pkgs.coreutils
        pkgs.util-linux
        py
      ];

      taskLabel = "managed_state";
    };

    services.homelab.tasks.tasks."managed-state-restore" = {
      description = "Managed state runner (explicit restore mode)";
      command = [ "${runner}/bin/managed-state-runner" "restore" ];

      schedule = null;
      persistent = false;
      timeoutSec = cfg.timeoutSec;

      requiresNetworkOnline = true;

      stateDirectory = "homelab-managed-state";
      environment = {
        HOME = "/var/lib/homelab-managed-state";
        MANAGED_STATE_CONFIG = cfg.configPath;
      };

      protectHome = "no";
      readOnlyPaths = [ "/root/.ssh" cfg.configPath ];
      readWritePaths = lib.unique (cfg.readablePaths ++ cfg.writablePaths);

      path = [
        pkgs.rsync
        pkgs.openssh
        pkgs.coreutils
        pkgs.util-linux
        py
      ];

      taskLabel = "managed_state_restore";
    };
  };
}