#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import sys
from copy import deepcopy
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    print("ERROR: Missing dependency: pyyaml", file=sys.stderr)
    sys.exit(1)

try:
    import jsonschema
except ImportError:
    print("ERROR: Missing dependency: jsonschema", file=sys.stderr)
    sys.exit(1)


REPO_ROOT = Path(__file__).resolve().parents[2]
INVENTORY_DIR = REPO_ROOT / "inventory"
HOSTS_DIR = INVENTORY_DIR / "hosts"
SCHEMA_PATH = INVENTORY_DIR / "schemas" / "host.schema.json"
GENERATED_DIR = INVENTORY_DIR / "generated"
GENERATED_NIX_DIR = GENERATED_DIR / "nix"
GENERATED_TERRAFORM_DIR = GENERATED_DIR / "terraform"


def load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict):
        raise ValueError(f"{path}: top-level YAML must be an object")
    return data


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"{path}: top-level JSON must be an object")
    return data


def deep_get(d: dict[str, Any], *keys: str, default: Any = None) -> Any:
    current: Any = d
    for key in keys:
        if not isinstance(current, dict) or key not in current:
            return default
        current = current[key]
    return current


def normalize_mac(mac: str) -> str:
    mac = mac.strip().lower()
    mac = re.sub(r"[^0-9a-f]", "", mac)
    if len(mac) != 12:
        return mac
    return ":".join(mac[i:i + 2] for i in range(0, 12, 2))


def apply_defaults(host: dict[str, Any]) -> dict[str, Any]:
    result = deepcopy(host)

    resources = result.setdefault("resources", {})
    cpu = resources.setdefault("cpu", {})
    cpu.setdefault("type", "host")

    network = result.setdefault("network", {})
    if network.get("mode") == "static":
        ipv4 = network.setdefault("ipv4", {})
        ipv4.setdefault("prefix", 24)

    provisioning = result.setdefault("provisioning", {})
    terraform = provisioning.setdefault("terraform", {})
    terraform.setdefault("datastore", "local-lvm")
    terraform.setdefault("bridge", "vmbr0")

    memory_mb = resources.get("memory_mb")
    if memory_mb is not None:
        terraform.setdefault("balloon_mb", memory_mb)

    return result


def validate_host(host: dict[str, Any], schema: dict[str, Any], source: Path) -> None:
    validator = jsonschema.Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(host), key=lambda e: list(e.path))

    if errors:
        lines = [f"Schema validation failed for {source}:"]
        for error in errors:
            path = ".".join(str(part) for part in error.absolute_path) or "<root>"
            lines.append(f"  - {path}: {error.message}")
        raise ValueError("\n".join(lines))

    if host["platform"] == "nixos" and host["management"]["converger"] != "nixos":
        raise ValueError(
            f"{source}: platform=nixos requires management.converger=nixos"
        )


def validate_cross_host(hosts: dict[str, dict[str, Any]]) -> None:
    seen_names: set[str] = set()
    seen_hostnames: set[str] = set()
    seen_ips: set[str] = set()
    seen_macs: set[str] = set()
    seen_vm_keys: set[tuple[str, int]] = set()

    for host in hosts.values():
        name = host["name"]
        hostname = host["hostname"]

        if name in seen_names:
            raise ValueError(f"Duplicate host name detected: {name}")
        seen_names.add(name)

        if hostname in seen_hostnames:
            raise ValueError(f"Duplicate hostname detected: {hostname}")
        seen_hostnames.add(hostname)

        network = host.get("network", {})
        mode = network.get("mode")

        if mode == "static":
            ip = deep_get(network, "ipv4", "address")
            if ip:
                if ip in seen_ips:
                    raise ValueError(f"Duplicate IP detected: {ip}")
                seen_ips.add(ip)

        elif mode == "dhcp-reservation":
            ip = deep_get(network, "reservation", "ip")
            mac = deep_get(network, "reservation", "mac")
            if ip:
                if ip in seen_ips:
                    raise ValueError(f"Duplicate IP detected: {ip}")
                seen_ips.add(ip)
            if mac:
                norm_mac = normalize_mac(mac)
                if norm_mac in seen_macs:
                    raise ValueError(f"Duplicate MAC detected: {mac}")
                seen_macs.add(norm_mac)

        runtime = host.get("runtime", {})
        if runtime.get("kind") == "vm" and runtime.get("vmid") is not None:
            vm_key = (runtime.get("node"), runtime["vmid"])
            if vm_key in seen_vm_keys:
                raise ValueError(
                    f"Duplicate VMID detected on node {runtime.get('node')}: {runtime['vmid']}"
                )
            seen_vm_keys.add(vm_key)


def build_nix_hosts_json(hosts: dict[str, dict[str, Any]]) -> dict[str, Any]:
    return {host["name"]: host for host in hosts.values()}


def derive_tags(host: dict[str, Any]) -> list[str]:
    tags: list[str] = ["gitops", "terraform", host["variant"], host["role"]]
    for group in host.get("groups", []):
        if group not in tags:
            tags.append(group)
    return tags


def build_tf_host_payload(host: dict[str, Any]) -> dict[str, Any]:
    network = host["network"]
    resources = host["resources"]
    runtime = host["runtime"]

    tf_payload: dict[str, Any] = {
        "ip": None,
        "ssh_user": "lab",
        "cpu": resources["cpu"]["cores"],
        "memory_mb": resources["memory_mb"],
        "disk_gb": resources["disk_gb"],
        "template_ref": None,
        "node": runtime.get("node"),
        "ipconfig": None,
        "tags": derive_tags(host),
    }

    if network["mode"] == "static":
        ipv4 = network["ipv4"]
        tf_payload["ip"] = ipv4["address"]
        tf_payload["ipconfig"] = f"ip={ipv4['address']}/{ipv4['prefix']},gw={ipv4['gateway']}"
    elif network["mode"] == "dhcp":
        tf_payload["ipconfig"] = "ip=dhcp"
    elif network["mode"] == "dhcp-reservation":
        reservation = network["reservation"]
        tf_payload["ip"] = reservation["ip"]
        tf_payload["ipconfig"] = "ip=dhcp"
        tf_payload["mac"] = normalize_mac(reservation["mac"])

    return {k: v for k, v in tf_payload.items() if v is not None}


def build_terraform_host_json(host: dict[str, Any]) -> dict[str, Any]:
    return {
        "hosts": {
            host["name"]: {
                "platform": host["platform"],
                "variant": host["variant"],
                "terraform": build_tf_host_payload(host)
            }
        }
    }


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=True)
        f.write("\n")


def main() -> int:
    if not HOSTS_DIR.exists():
        print(f"ERROR: Hosts directory not found: {HOSTS_DIR}", file=sys.stderr)
        return 1

    schema = load_json(SCHEMA_PATH)

    raw_hosts: list[tuple[Path, dict[str, Any]]] = []
    for path in sorted(HOSTS_DIR.glob("*.yaml")):
        raw_hosts.append((path, load_yaml(path)))

    if not raw_hosts:
        print(f"ERROR: No host YAML files found in {HOSTS_DIR}", file=sys.stderr)
        return 1

    processed_hosts: dict[str, dict[str, Any]] = {}

    for path, raw_host in raw_hosts:
        host = apply_defaults(raw_host)
        validate_host(host, schema, path)

        host_name = host["name"]
        if host_name in processed_hosts:
            raise ValueError(f"Duplicate inventory key detected: {host_name}")

        processed_hosts[host_name] = host

    validate_cross_host(processed_hosts)

    nix_hosts = build_nix_hosts_json(processed_hosts)
    write_json(GENERATED_NIX_DIR / "hosts.json", nix_hosts)

    GENERATED_TERRAFORM_DIR.mkdir(parents=True, exist_ok=True)
    for host in processed_hosts.values():
        if host["management"]["provisioner"] != "terraform":
            continue
        write_json(
            GENERATED_TERRAFORM_DIR / f"{host['name']}.json",
            build_terraform_host_json(host),
        )

    print("Rendered inventory successfully:")
    print(f"  - {GENERATED_NIX_DIR / 'hosts.json'}")
    for host in processed_hosts.values():
        if host["management"]["provisioner"] == "terraform":
            tf_path = GENERATED_TERRAFORM_DIR / f"{host['name']}.json"
            print(f"  - {tf_path}")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
