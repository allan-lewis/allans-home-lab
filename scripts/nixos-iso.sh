#!/usr/bin/env bash
set -euo pipefail

# scripts/nixos-iso.sh
#
# Generate files to build a custom NixOS autoinstall ISO for a bare-metal host.
# - Installer boots, prints disk info, requires 30s confirmation, wipes disk, installs NixOS, reboots.
# - Installed system uses static IPv4 on a specified interface.
#
# Build (after generation):
#   cd <outdir>
#   nix build .#iso
#
# Required env:
#   SSH_PUBLIC_KEY="ssh-ed25519 AAAA..."

usage() {
  cat <<'EOF' >&2
Usage:
  SSH_PUBLIC_KEY="ssh-ed25519 AAAA..." \
  scripts/nixos-iso.sh \
    --out <dir> \
    --hostname <name> \
    --disk </dev/sda|/dev/nvme0n1> \
    --iface <iface> \
    --ip <addr/cidr> \
    [--user lab] \
    [--state-version 25.11] \
    [--nixpkgs nixos-25.11]

Notes:
- --ip must include CIDR, e.g. 192.168.86.82/24
- gateway and dns are derived as network+1 (first usable host)
EOF
  exit 2
}

OUT=""
HOSTNAME=""
DISK=""
IFACE=""
IP_CIDR=""
USER_NAME="lab"
STATE_VERSION="25.11"
NIXPKGS_REF="nixos-25.11"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) OUT="$2"; shift 2 ;;
    --hostname) HOSTNAME="$2"; shift 2 ;;
    --disk) DISK="$2"; shift 2 ;;
    --iface) IFACE="$2"; shift 2 ;;
    --ip) IP_CIDR="$2"; shift 2 ;;
    --user) USER_NAME="$2"; shift 2 ;;
    --state-version) STATE_VERSION="$2"; shift 2 ;;
    --nixpkgs) NIXPKGS_REF="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

: "${OUT:?--out is required}"
: "${HOSTNAME:?--hostname is required}"
: "${DISK:?--disk is required}"
: "${IFACE:?--iface is required}"
: "${IP_CIDR:?--ip is required}"

if [[ -z "${SSH_PUBLIC_KEY:-}" ]]; then
  echo "ERROR: SSH_PUBLIC_KEY env var is required (SSH public key)." >&2
  exit 1
fi

# Keep IP parsing logic as-is
IP_ADDR="${IP_CIDR%/*}"
PREFIX="${IP_CIDR#*/}"
if [[ "$IP_ADDR" == "$PREFIX" ]]; then
  echo "ERROR: --ip must be CIDR (e.g. 192.168.86.82/24)" >&2
  exit 1
fi

# Derive GW/DNS as first usable IP (network + 1)
read -r GW DNS < <(
  python3 - <<PY
import ipaddress
net = ipaddress.ip_network("${IP_CIDR}", strict=False)
gw = str(list(net.hosts())[0])
print(gw, gw)
PY
)

mkdir -p "$OUT"

# Write installer.nix WITHOUT bash expanding Nix ${...}
cat > "$OUT/installer.nix" <<'NIX'
{ modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  #
  # Installer environment
  #
  services.openssh.enable = true;
  networking.useDHCP = true;

  users.users.__USER__ = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "__SSH_PUBLIC_KEY__" ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    curl
    util-linux
    e2fsprogs
    dosfstools
    parted
  ];

  #
  # Auto-install service (DESTROYS DISK CONTENTS).
  # Adds a 30-second confirmation window and prints disk info.
  #
  systemd.services.autoinstall = {
    description = "Automatic NixOS install (requires confirmation) to __DISK__";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
    };

    script = ''
      set -Eeuo pipefail

      DISK="__DISK__"

      echo
      echo "============================================================"
      echo " AUTOINSTALL: THIS WILL WIPE AND REPARTITION THE TARGET DISK "
      echo "============================================================"
      echo
      echo "Host (installed): __HOSTNAME__"
      echo "Operator user:    __USER__"
      echo
      echo "Installed network (static):"
      echo "  iface: __IFACE__"
      echo "  ip:    __IP_ADDR__/__PREFIX__"
      echo "  gw:    __GW__"
      echo "  dns:   __DNS__"
      echo
      echo "Target disk:      $DISK"
      echo

      echo "Disk inventory (lsblk):"
      ${pkgs.util-linux}/bin/lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT,MODEL,SERIAL,WWN,UUID || true
      echo

      echo "Target disk details (lsblk -d):"
      ${pkgs.util-linux}/bin/lsblk -d -o NAME,PATH,SIZE,MODEL,SERIAL,WWN,TYPE "$DISK" || true
      echo

      echo "Existing filesystem signatures on target disk (wipefs):"
      ${pkgs.util-linux}/bin/wipefs -n "$DISK" || true
      echo

      echo "By-id / by-path hints (if present):"
      ls -l /dev/disk/by-id 2>/dev/null | sed -n '1,200p' || true
      echo
      ls -l /dev/disk/by-path 2>/dev/null | sed -n '1,200p' || true
      echo

      echo "============================================================"
      echo "CONFIRMATION REQUIRED"
      echo "============================================================"
      echo "Type exactly: WIPE $DISK"
      echo "You have 30 seconds..."
      echo

      if ! read -r -t 30 reply; then
        echo "Timed out. Aborting install."
        exit 1
      fi

      if [[ "$reply" != "WIPE $DISK" ]]; then
        echo "Confirmation mismatch ('$reply'). Aborting install."
        exit 1
      fi

      echo
      echo "Confirmed. Proceeding to wipe and install."
      echo

      ${pkgs.parted}/bin/parted "$DISK" -- mklabel gpt
      ${pkgs.parted}/bin/parted "$DISK" -- mkpart ESP fat32 1MiB 512MiB
      ${pkgs.parted}/bin/parted "$DISK" -- set 1 esp on
      ${pkgs.parted}/bin/parted "$DISK" -- mkpart primary ext4 512MiB 100%

      partprefix=""
      if [[ "$DISK" =~ nvme ]]; then partprefix="p"; fi

      EFI="${DISK}${partprefix}1"
      ROOT="${DISK}${partprefix}2"

      ${pkgs.dosfstools}/bin/mkfs.fat -F32 -n boot "$EFI"
      ${pkgs.e2fsprogs}/bin/mkfs.ext4 -F -L nixos "$ROOT"

      mount "$ROOT" /mnt
      mkdir -p /mnt/boot
      mount "$EFI" /mnt/boot

      ${pkgs.nixos-install-tools}/bin/nixos-generate-config --root /mnt

      cat > /mnt/etc/nixos/configuration.nix <<'NIXCONF'
{ pkgs, ... }:

{
  networking = {
    hostName = "__HOSTNAME__";
    useDHCP = false;
    interfaces.__IFACE__.ipv4.addresses = [
      { address = "__IP_ADDR__"; prefixLength = __PREFIX__; }
    ];
    defaultGateway = "__GW__";
    nameservers = [ "__DNS__" ];
  };

  services.openssh.enable = true;

  users.users.__USER__ = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "__SSH_PUBLIC_KEY__" ];
  };

  security.sudo.wheelNeedsPassword = false;
  services.timesyncd.enable = true;

  system.stateVersion = "__STATE_VERSION__";
}
NIXCONF

      ${pkgs.nixos-install-tools}/bin/nixos-install --no-root-passwd

      echo
      echo "Install complete. Rebooting..."
      reboot
    '';
  };
}
NIX

# Substitute placeholders (portable; avoids bash interpreting Nix ${...})
tmp="$(mktemp)"
sed \
  -e "s|__HOSTNAME__|$HOSTNAME|g" \
  -e "s|__DISK__|$DISK|g" \
  -e "s|__IFACE__|$IFACE|g" \
  -e "s|__IP_ADDR__|$IP_ADDR|g" \
  -e "s|__PREFIX__|$PREFIX|g" \
  -e "s|__GW__|$GW|g" \
  -e "s|__DNS__|$DNS|g" \
  -e "s|__USER__|$USER_NAME|g" \
  -e "s|__STATE_VERSION__|$STATE_VERSION|g" \
  -e "s|__SSH_PUBLIC_KEY__|$SSH_PUBLIC_KEY|g" \
  "$OUT/installer.nix" > "$tmp"
mv "$tmp" "$OUT/installer.nix"

# flake.nix (safe to template normally)
cat > "$OUT/flake.nix" <<EOF
{
  description = "Autoinstall NixOS ISO (bare metal bootstrap)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/${NIXPKGS_REF}";

  outputs = { self, nixpkgs }:
  {
    nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./installer.nix ];
    };

    packages.x86_64-linux.iso =
      self.nixosConfigurations.installer.config.system.build.isoImage;
  };
}
EOF

cat > "$OUT/README.md" <<EOF
# Autoinstall ISO (bare metal bootstrap)

Generated for:
- hostname: ${HOSTNAME}
- disk:     ${DISK}
- iface:    ${IFACE}
- ip:       ${IP_ADDR}/${PREFIX}
- gw:       ${GW}   (derived: network + 1)
- dns:      ${DNS}  (derived: same as gw)
- user:     ${USER_NAME}

Build ISO:
  cd $(basename "$OUT")
  nix build .#iso

Safety:
- On boot, prints disk info and requires interactive confirmation:
    Type exactly:  WIPE ${DISK}
  within 30 seconds, or it aborts.

SSH key:
- Embedded at generation time from env var SSH_PUBLIC_KEY
EOF

echo "Wrote installer files to: $OUT"
echo "Derived gateway/DNS: $GW"
echo "Next:"
echo "  cd $OUT"
echo "  nix build .#iso"