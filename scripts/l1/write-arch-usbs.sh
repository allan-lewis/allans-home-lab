#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi

die() {
  echo "ERROR: $*" >&2
  exit 1
}
info() { echo "==> $*"; }

require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }
for c in lsblk dd wipefs findmnt blkid readlink; do require_cmd "$c"; done

INSTALLER_ISO="${1:-}"
SEED_ISO="${2:-}"

[[ -f "$INSTALLER_ISO" ]] || die "Installer ISO not found: $INSTALLER_ISO"
[[ -f "$SEED_ISO" ]] || die "Seed ISO not found: $SEED_ISO"

# Identify the disk backing /
root_src="$(findmnt -n -o SOURCE / || true)"
root_dev="$(readlink -f "$root_src" 2>/dev/null || true)"
root_disk="$(lsblk -no PKNAME "$root_dev" 2>/dev/null || true)"
root_disk="${root_disk:+/dev/$root_disk}"

info "Root filesystem source: ${root_src:-unknown}"
info "Root disk: ${root_disk:-unknown}"
echo

info "Scanning USB disks (TRAN=usb)..."

mapfile -t DISK_LINES < <(
  lsblk -dn -o NAME,TYPE,TRAN,SIZE,MODEL |
    awk '$2=="disk" && $3=="usb" {print}'
)

((${#DISK_LINES[@]} >= 2)) || die "Need at least 2 USB disks visible to this machine (TRAN=usb)."

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
  # If any partition of the disk is mounted, reject
  findmnt -rn -S "${dev}" >/dev/null 2>&1 && return 0
  # Also check children partitions explicitly
  while read -r child; do
    findmnt -rn -S "$child" >/dev/null 2>&1 && return 0
  done < <(lsblk -ln -o PATH "$dev" | tail -n +2)
  return 1
}

pick_disk() {
  local prompt="$1"
  local dev
  while true; do
    read -rp "${prompt} (e.g. /dev/sdb): " dev
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
      echo "Disk (or a partition) is mounted; unmount first: $dev"
      continue
    fi

    echo "$dev"
    return
  done
}

info "Installer ISO: $INSTALLER_ISO"
info "Seed ISO:      $SEED_ISO"
echo

INSTALL_DISK="$(pick_disk 'Select USB for INSTALLER ISO')"
SEED_DISK="$(pick_disk 'Select USB for SEED ISO')"
[[ "$INSTALL_DISK" != "$SEED_DISK" ]] || die "Both selections are the same disk"

echo
info "Summary:"
echo "  Installer → $INSTALL_DISK"
echo "  Seed      → $SEED_DISK"
echo

read -rp "Type 'YES' to continue: " c1
[[ "$c1" == "YES" ]] || die "Aborted"

read -rp "Re-type installer disk ($INSTALL_DISK) to confirm: " c2
[[ "$c2" == "$INSTALL_DISK" || "/dev/$c2" == "$INSTALL_DISK" ]] || die "Mismatch"

read -rp "Re-type seed disk ($SEED_DISK) to confirm: " c3
[[ "$c3" == "$SEED_DISK" || "/dev/$c3" == "$SEED_DISK" ]] || die "Mismatch"

info "Wiping filesystem signatures..."
wipefs -a "$INSTALL_DISK"
wipefs -a "$SEED_DISK"

info "Writing installer ISO..."
dd if="$INSTALLER_ISO" of="$INSTALL_DISK" bs=4M status=progress conv=fsync

info "Writing seed ISO..."
dd if="$SEED_ISO" of="$SEED_DISK" bs=4M status=progress conv=fsync

sync
info "Done. USB sticks are ready."

info "Post-write blkid (best-effort):"
blkid "$INSTALL_DISK" || true
blkid "$SEED_DISK" || true
