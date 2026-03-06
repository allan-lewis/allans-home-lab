#!/usr/bin/env bash
set -euo pipefail

# scripts/nixos-iso.sh
#
# Generate files to build a custom NixOS autoinstall ISO for a bare-metal host.
#
# What the ISO does when booted:
# - Prints disk info
# - Optional short countdown window (Ctrl-C abort) to avoid brittle interactive prompts
# - Wipes disk, partitions GPT (EFI + root), installs minimal NixOS bootstrap, reboots
#
# Build command (run INSIDE the generated directory):
#   nix build "path:$(pwd)#iso"
#
# Required env:
#   TF_VAR_PROXMOX_VM_PUBLIC_KEY="ssh-ed25519 AAAA..."

usage() {
  cat <<'EOF' >&2
Usage:
  TF_VAR_PROXMOX_VM_PUBLIC_KEY="ssh-ed25519 AAAA..." \
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
  --out)
    OUT="$2"
    shift 2
    ;;
  --hostname)
    HOSTNAME="$2"
    shift 2
    ;;
  --disk)
    DISK="$2"
    shift 2
    ;;
  --iface)
    IFACE="$2"
    shift 2
    ;;
  --ip)
    IP_CIDR="$2"
    shift 2
    ;;
  --user)
    USER_NAME="$2"
    shift 2
    ;;
  --state-version)
    STATE_VERSION="$2"
    shift 2
    ;;
  --nixpkgs)
    NIXPKGS_REF="$2"
    shift 2
    ;;
  -h | --help) usage ;;
  *)
    echo "Unknown arg: $1" >&2
    usage
    ;;
  esac
done

: "${OUT:?--out is required}"
: "${HOSTNAME:?--hostname is required}"
: "${DISK:?--disk is required}"
: "${IFACE:?--iface is required}"
: "${IP_CIDR:?--ip is required}"

if [[ -z "${TF_VAR_PROXMOX_VM_PUBLIC_KEY:-}" ]]; then
  echo "ERROR: TF_VAR_PROXMOX_VM_PUBLIC_KEY env var is required (SSH public key)." >&2
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

cat >"$OUT/installer.nix" <<'NIX'
{ lib, modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  #
  # Installer environment
  #
  services.openssh.enable = true;

  # Minimal ISO module stack may set this false (e.g. via NetworkManager).
  networking.useDHCP = lib.mkForce true;

  users.users.__USER__ = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "__TF_VAR_PROXMOX_VM_PUBLIC_KEY__" ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    coreutils
    util-linux
    e2fsprogs
    dosfstools
    gnugrep
    gnused
    parted
    python3
    sudo
    systemd
    git
    curl
  ];

  #
  # Auto-install service (DESTROYS DISK CONTENTS).
  # NOTE: intentionally non-interactive for stability.
  #
  systemd.services.autoinstall = {
    description = "Automatic NixOS install to __DISK__";
    wantedBy = [ "multi-user.target" ];

    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
    };

    script = ''
      set -Eeuo pipefail

      # Make installer tools reliable under systemd
      export PATH="/run/current-system/sw/bin:/run/wrappers/bin:$PATH"
      export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix"
      export NIX_CONFIG="experimental-features = nix-command flakes"

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

      echo "Existing filesystem signatures on target disk (wipefs -n):"
      ${pkgs.util-linux}/bin/wipefs -n "$DISK" || true
      echo

      # Stable safety window: countdown + Ctrl-C abort.
      echo "Starting destructive install in 10 seconds..."
      echo "Press Ctrl-C NOW to abort."
      for i in 10 9 8 7 6 5 4 3 2 1; do
        echo "  ...$i"
        ${pkgs.coreutils}/bin/sleep 1
      done
      echo

      # Partition paths (no brace expansion)
      if [[ "$DISK" =~ nvme ]]; then
        EFI="$DISK"p1
        ROOT="$DISK"p2
      else
        EFI="$DISK"1
        ROOT="$DISK"2
      fi

      # Best-effort unmount from previous attempts (prevents "partitions in use")
      ${pkgs.util-linux}/bin/umount -R /mnt 2>/dev/null || true
      ${pkgs.util-linux}/bin/umount "$EFI" 2>/dev/null || true
      ${pkgs.util-linux}/bin/umount "$ROOT" 2>/dev/null || true

      # Remove signatures before repartitioning
      ${pkgs.util-linux}/bin/wipefs -a "$DISK" || true

      # Partition non-interactively
      ${pkgs.parted}/bin/parted -s "$DISK" \
        mklabel gpt \
        mkpart ESP fat32 1MiB 512MiB \
        set 1 esp on \
        mkpart primary ext4 512MiB 100%

      ${pkgs.systemd}/bin/udevadm settle

      # Recompute partition paths (same rule as above)
      if [[ "$DISK" =~ nvme ]]; then
        EFI="$DISK"p1
        ROOT="$DISK"p2
      else
        EFI="$DISK"1
        ROOT="$DISK"2
      fi

      ${pkgs.dosfstools}/bin/mkfs.fat -F32 -n boot "$EFI"
      ${pkgs.e2fsprogs}/bin/mkfs.ext4 -F -L nixos "$ROOT"

      ${pkgs.util-linux}/bin/mount "$ROOT" /mnt
      ${pkgs.coreutils}/bin/mkdir -p /mnt/boot
      ${pkgs.util-linux}/bin/mount "$EFI" /mnt/boot

      ${pkgs.nixos-install-tools}/bin/nixos-generate-config --root /mnt

      # Bootloader snippet (UEFI vs BIOS)
      BOOT_SNIPPET=""
      if [[ -d /sys/firmware/efi ]]; then
        BOOT_SNIPPET=$'  boot.loader.systemd-boot.enable = true;\n  boot.loader.efi.canTouchEfiVariables = true;\n'
      else
        BOOT_SNIPPET=$'  boot.loader.grub.enable = true;\n  boot.loader.grub.devices = [ "'"$DISK"'" ];\n'
      fi

      # Write bootstrap config, preserving generated hardware config import
      cat > /mnt/etc/nixos/configuration.nix <<NIXCONF
{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];
$BOOT_SNIPPET
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
    openssh.authorizedKeys.keys = [ "__TF_VAR_PROXMOX_VM_PUBLIC_KEY__" ];
  };

  security.sudo.wheelNeedsPassword = false;
  services.timesyncd.enable = true;

  system.stateVersion = "__STATE_VERSION__";
}
NIXCONF

      ${pkgs.nixos-install-tools}/bin/nixos-install --no-root-passwd

      echo
      echo "Install complete. Rebooting..."
      ${pkgs.systemd}/bin/reboot
    '';
  };
}
NIX

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
  -e "s|__TF_VAR_PROXMOX_VM_PUBLIC_KEY__|$TF_VAR_PROXMOX_VM_PUBLIC_KEY|g" \
  "$OUT/installer.nix" >"$tmp"
mv "$tmp" "$OUT/installer.nix"

cat >"$OUT/flake.nix" <<EOF
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

cat >"$OUT/README.md" <<EOF
# Autoinstall ISO (bare metal bootstrap)

Generated for:
- hostname: ${HOSTNAME}
- disk:     ${DISK}
- iface:    ${IFACE}
- ip:       ${IP_ADDR}/${PREFIX}
- gw:       ${GW}   (derived: network + 1)
- dns:      ${DNS}  (derived: same as gw)
- user:     ${USER_NAME}

Build ISO (run inside this directory):
  nix build "path:\$(pwd)#iso"

Notes:
- The installer is intentionally non-interactive for stability.
- A short countdown window is provided; press Ctrl-C on the console to abort before disk wipe.

SSH key:
- Embedded at generation time from env var TF_VAR_PROXMOX_VM_PUBLIC_KEY
EOF

echo "Wrote installer files to: $OUT"
echo "Derived gateway/DNS: $GW"

echo
echo "Building ISO..."
(
  cd "$OUT"
  nix build "path:$(pwd)#iso"
)

echo
echo "ISO build complete."
echo "Location:"
echo "  $OUT/result/iso/"

# --- OPTIONAL: write built ISO to a removable USB disk (DANGEROUS) ---

die() {
  echo "ERROR: $*" >&2
  exit 1
}
info() { echo "==> $*"; }

require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }
for c in lsblk dd wipefs findmnt blkid readlink awk sed; do require_cmd "$c"; done

SUDO=""
if [[ $EUID -ne 0 ]]; then
  SUDO="sudo -E"
fi

ISO_DIR="$OUT/result/iso"
ISO_PATH="$(ls -1 "$ISO_DIR"/*.iso 2>/dev/null | head -n1 || true)"
[[ -f "$ISO_PATH" ]] || die "Built ISO not found under: $ISO_DIR"

echo
info "ISO ready: $ISO_PATH"
echo

root_src="$(findmnt -n -o SOURCE / || true)"
root_dev="$(readlink -f "$root_src" 2>/dev/null || true)"
root_disk="$(lsblk -no PKNAME "$root_dev" 2>/dev/null || true)"
root_disk="${root_disk:+/dev/$root_disk}"

info "Root filesystem source: ${root_src:-unknown}"
info "Root disk: ${root_disk:-unknown}"
echo

info "Scanning removable USB disks (TRAN=usb)..."

mapfile -t DISK_LINES < <(
  lsblk -dn -o NAME,TYPE,TRAN,SIZE,MODEL |
    awk '$2=="disk" && $3=="usb" {print}'
)

((${#DISK_LINES[@]} >= 1)) || die "No removable USB disks detected (TRAN=usb)."

echo
printf "%-12s %-6s %-6s %-10s %-30s\n" "DEVICE" "TYPE" "TRAN" "SIZE" "MODEL"
echo "---------------------------------------------------------------------"
for line in "${DISK_LINES[@]}"; do
  dev="$(awk '{print $1}' <<<"$line")"
  type="$(awk '{print $2}' <<<"$line")"
  tran="$(awk '{print $3}' <<<"$line")"
  size="$(awk '{print $4}' <<<"$line")"
  model="$(cut -d' ' -f5- <<<"$line")"
  printf "%-12s %-6s %-6s %-10s %-30s\n" "/dev/$dev" "$type" "$tran" "$size" "$model"
done
echo

is_usb_disk() {
  local dev="$1"
  lsblk -dn -o TYPE,TRAN "$dev" | awk '
    $1=="disk" && $2=="usb" { found=1 }
    END { exit(found ? 0 : 1) }
  '
}

is_mounted_anywhere() {
  local dev="$1"
  findmnt -rn -S "$dev" >/dev/null 2>&1 && return 0
  while read -r child; do
    findmnt -rn -S "$child" >/dev/null 2>&1 && return 0
  done < <(lsblk -ln -o PATH "$dev" | tail -n +2)
  return 1
}

pick_disk() {
  local prompt="$1"
  local dev
  while true; do
    read -rp "$prompt (e.g. /dev/sdb): " dev
    [[ -n "$dev" ]] || continue
    [[ "$dev" =~ ^/dev/ ]] || dev="/dev/$dev"
    [[ -b "$dev" ]] || {
      echo "Not a block device: $dev"
      continue
    }

    is_usb_disk "$dev" || {
      echo "Not a USB disk (TRAN=usb required): $dev"
      continue
    }

    if [[ -n "$root_disk" && "$dev" == "$root_disk" ]]; then
      echo "Refusing to use root disk: $dev"
      continue
    fi

    if is_mounted_anywhere "$dev"; then
      echo "Disk (or partition) is mounted; unmount first: $dev"
      continue
    fi

    echo "$dev"
    return
  done
}

USB_DISK="$(pick_disk 'Select USB disk to write ISO to')"

echo
info "Summary:"
echo "  ISO → $ISO_PATH"
echo "  USB → $USB_DISK"
echo

read -rp "Type 'YES' to continue: " c1
[[ "$c1" == "YES" ]] || die "Aborted"

read -rp "Re-type USB disk ($USB_DISK) to confirm: " c2
[[ "$c2" == "$USB_DISK" || "/dev/$c2" == "$USB_DISK" ]] || die "Mismatch"

read -rp "Type exactly: WIPE $USB_DISK : " c3
[[ "$c3" == "WIPE $USB_DISK" ]] || die "Mismatch"

info "Wiping filesystem signatures..."
$SUDO wipefs -a "$USB_DISK"

info "Writing ISO to USB..."
$SUDO dd if="$ISO_PATH" of="$USB_DISK" bs=4M status=progress conv=fsync

$SUDO sync
info "Done. USB stick is ready."

info "Post-write blkid (best-effort):"
$SUDO blkid "$USB_DISK" || true