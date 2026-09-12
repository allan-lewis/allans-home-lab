#!/usr/bin/env bash
set -euo pipefail

HOSTNAME="${1:?Usage: $0 <hostname> <disk> <interface> <ip_cidr>}"
DISK="${2:?Usage: $0 <hostname> <disk> <interface> <ip_cidr>}"
IFACE="${3:?Usage: $0 <hostname> <disk> <interface> <ip_cidr>}"
IP_CIDR="${4:?Usage: $0 <hostname> <disk> <interface> <ip_cidr>}"

OUT=".build/nix-iso/${HOSTNAME}"
: "${OUT:?--out is required}"

USER_NAME="lab"
STATE_VERSION="26.05"
NIXPKGS_REF="nixos-26.05"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

info() {
  echo "==> $*"
}

# Escape a string for use as the replacement side of sed s|...|...|.
sed_replacement_escape() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

# -----------------------------------------------------------------------------
# Authentication choice
# -----------------------------------------------------------------------------

AUTH_MODE="ssh-key"
AUTH_MODE_DESC="SSH public key"
PASSWORD_HASH=""
SSH_PASSWORD_SETTING=""
AUTH_LINE='openssh.authorizedKeys.keys = [ "__TF_VAR_PROXMOX_VM_PUBLIC_KEY__" ];'

while true; do
  read -r -p "Specify a password for the ${USER_NAME} user? [y/N]: " use_password
  case "${use_password:-N}" in
  [Yy] | [Yy][Ee][Ss])
    AUTH_MODE="password"
    break
    ;;
  [Nn] | [Nn][Oo] | "")
    AUTH_MODE="ssh-key"
    break
    ;;
  *)
    echo "Please answer y or n."
    ;;
  esac
done

if [[ "$AUTH_MODE" == "password" ]]; then
  while true; do
    read -r -s -p "Password for ${USER_NAME}: " password1
    echo
    read -r -s -p "Confirm password: " password2
    echo

    if [[ -z "$password1" ]]; then
      echo "Password cannot be empty."
      continue
    fi

    if [[ "$password1" != "$password2" ]]; then
      echo "Passwords do not match. Try again."
      continue
    fi

    break
  done

  if command -v mkpasswd >/dev/null 2>&1; then
    PASSWORD_HASH="$(printf '%s\n' "$password1" | mkpasswd -m yescrypt -s)"
  elif command -v nix >/dev/null 2>&1; then
    PASSWORD_HASH="$(printf '%s\n' "$password1" | nix shell nixpkgs#whois -c mkpasswd -m yescrypt -s)"
  else
    unset password1 password2
    die "Password mode requires either 'mkpasswd' or 'nix' so a yescrypt hash can be generated."
  fi

  unset password1 password2

  [[ -n "$PASSWORD_HASH" ]] || die "Password hashing returned an empty value."
  [[ "$PASSWORD_HASH" == '$y$'* ]] || die "Expected a yescrypt hash beginning with '\$y\$', but mkpasswd returned something else."
  [[ "$PASSWORD_HASH" != *'${'* ]] || die "Generated password hash contains an unsafe Nix interpolation sequence."

  SSH_PASSWORD_SETTING='settings.PasswordAuthentication = true;'
  AUTH_LINE='hashedPassword = "__PASSWORD_HASH__";'
  AUTH_MODE_DESC="username/password"
else
  [[ -n "${TF_VAR_PROXMOX_VM_PUBLIC_KEY:-}" ]] ||
    die "TF_VAR_PROXMOX_VM_PUBLIC_KEY env var is required when password login is not selected."

  [[ "$TF_VAR_PROXMOX_VM_PUBLIC_KEY" != *$'\n'* ]] || die "SSH public key must be a single line."
  [[ "$TF_VAR_PROXMOX_VM_PUBLIC_KEY" != *'"'* ]] || die "SSH public key contains a double quote and cannot safely be embedded."
fi

# -----------------------------------------------------------------------------
# Network values
# -----------------------------------------------------------------------------

IP_ADDR="${IP_CIDR%/*}"
PREFIX="${IP_CIDR#*/}"
if [[ "$IP_ADDR" == "$PREFIX" ]]; then
  die "IP must be CIDR (e.g. 192.168.86.82/24)."
fi

read -r GW DNS < <(
  python3 - <<PY
import ipaddress
net = ipaddress.ip_network("${IP_CIDR}", strict=False)
gw = str(next(net.hosts()))
print(gw, gw)
PY
)

echo "=== NixOS ISO build ==="
echo "Host name             : ${HOSTNAME}"
echo "Network interface     : ${IFACE}"
echo "Disk                  : ${DISK}"
echo "IP range              : ${IP_CIDR}"
echo "IP address            : ${IP_ADDR}"
echo "Authentication        : ${AUTH_MODE_DESC}"
echo "Output directory      : ${OUT}"
echo

mkdir -p "$OUT"

# -----------------------------------------------------------------------------
# Generate installer.nix
#
# IMPORTANT: The installed system's configuration is created at ISO BUILD TIME
# with pkgs.writeText and then copied into /mnt during installation.  We do NOT
# construct configuration.nix with a runtime shell heredoc.  This deliberately
# avoids shell expansion of yescrypt hashes such as "$y$...".
# -----------------------------------------------------------------------------

cat >"$OUT/installer.nix" <<'NIX'
{ lib, modulesPath, pkgs, ... }:

let
  bootstrapConfig = pkgs.writeText "bootstrap-configuration.nix" ''
    { pkgs, ... }:

    {
      imports = [ ./hardware-configuration.nix ];

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      networking = {
        hostName = "__HOSTNAME__";
        useDHCP = false;
        interfaces.__IFACE__.ipv4.addresses = [
          { address = "__IP_ADDR__"; prefixLength = __PREFIX__; }
        ];
        defaultGateway = "__GW__";
        nameservers = [ "__DNS__" ];
      };

      services.openssh = {
        enable = true;
        __SSH_PASSWORD_SETTING__
      };

      users.users.__USER__ = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        __AUTH_LINE__
      };

      security.sudo.wheelNeedsPassword = false;
      services.timesyncd.enable = true;

      environment.systemPackages = with pkgs; [
        python3
        git
        curl
        coreutils
        gnugrep
        gnused
      ];

      system.stateVersion = "__STATE_VERSION__";
    }
  '';
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  #
  # Installer environment
  #
  services.openssh = {
    enable = true;
    __SSH_PASSWORD_SETTING__
  };

  # Minimal ISO module stack may set this false (e.g. via NetworkManager).
  networking.useDHCP = lib.mkForce true;

  users.users.__USER__ = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    __AUTH_LINE__
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

      # Make installer tools reliable under systemd.
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

      # Partition names.  Devices whose base name ends in a digit (NVMe,
      # mmcblk, etc.) use p1/p2; sdX-style devices use 1/2.
      if [[ "$DISK" =~ [0-9]$ ]]; then
        EFI="$DISK"p1
        ROOT="$DISK"p2
      else
        EFI="$DISK"1
        ROOT="$DISK"2
      fi

      # Best-effort unmount from previous attempts.
      ${pkgs.util-linux}/bin/umount -R /mnt 2>/dev/null || true
      ${pkgs.util-linux}/bin/umount "$EFI" 2>/dev/null || true
      ${pkgs.util-linux}/bin/umount "$ROOT" 2>/dev/null || true

      # Remove signatures before repartitioning.
      ${pkgs.util-linux}/bin/wipefs -a "$DISK" || true

      # Partition non-interactively.
      ${pkgs.parted}/bin/parted -s "$DISK" \
        mklabel gpt \
        mkpart ESP fat32 1MiB 512MiB \
        set 1 esp on \
        mkpart primary ext4 512MiB 100%

      ${pkgs.systemd}/bin/udevadm settle

      # Recompute partition paths after partition table creation.
      if [[ "$DISK" =~ [0-9]$ ]]; then
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

      # Copy the pre-generated bootstrap configuration into place.  Because
      # this file was produced by Nix at ISO build time, the shell never parses
      # or expands the embedded password hash / SSH key.
      ${pkgs.coreutils}/bin/install -m 0644 ${bootstrapConfig} /mnt/etc/nixos/configuration.nix

      ${pkgs.nixos-install-tools}/bin/nixos-install --no-root-passwd

      echo
      echo "Install complete. Rebooting..."
      ${pkgs.systemd}/bin/reboot
    '';
  };
}
NIX

# Perform substitutions safely, including '&', '\\', and '|' if they ever
# occur in a replacement value.
HOSTNAME_SED="$(sed_replacement_escape "$HOSTNAME")"
DISK_SED="$(sed_replacement_escape "$DISK")"
IFACE_SED="$(sed_replacement_escape "$IFACE")"
IP_ADDR_SED="$(sed_replacement_escape "$IP_ADDR")"
PREFIX_SED="$(sed_replacement_escape "$PREFIX")"
GW_SED="$(sed_replacement_escape "$GW")"
DNS_SED="$(sed_replacement_escape "$DNS")"
USER_NAME_SED="$(sed_replacement_escape "$USER_NAME")"
STATE_VERSION_SED="$(sed_replacement_escape "$STATE_VERSION")"
SSH_PASSWORD_SETTING_SED="$(sed_replacement_escape "$SSH_PASSWORD_SETTING")"
AUTH_LINE_SED="$(sed_replacement_escape "$AUTH_LINE")"
PASSWORD_HASH_SED="$(sed_replacement_escape "$PASSWORD_HASH")"
SSH_KEY_SED="$(sed_replacement_escape "${TF_VAR_PROXMOX_VM_PUBLIC_KEY:-}")"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

sed \
  -e "s|__HOSTNAME__|$HOSTNAME_SED|g" \
  -e "s|__DISK__|$DISK_SED|g" \
  -e "s|__IFACE__|$IFACE_SED|g" \
  -e "s|__IP_ADDR__|$IP_ADDR_SED|g" \
  -e "s|__PREFIX__|$PREFIX_SED|g" \
  -e "s|__GW__|$GW_SED|g" \
  -e "s|__DNS__|$DNS_SED|g" \
  -e "s|__USER__|$USER_NAME_SED|g" \
  -e "s|__STATE_VERSION__|$STATE_VERSION_SED|g" \
  -e "s|__SSH_PASSWORD_SETTING__|$SSH_PASSWORD_SETTING_SED|g" \
  -e "s|__AUTH_LINE__|$AUTH_LINE_SED|g" \
  -e "s|__PASSWORD_HASH__|$PASSWORD_HASH_SED|g" \
  -e "s|__TF_VAR_PROXMOX_VM_PUBLIC_KEY__|$SSH_KEY_SED|g" \
  "$OUT/installer.nix" >"$tmp"

mv "$tmp" "$OUT/installer.nix"
trap - EXIT

# -----------------------------------------------------------------------------
# Preflight checks before the expensive ISO build / USB write.
# -----------------------------------------------------------------------------

if grep -Eq '__[A-Z0-9_]+__' "$OUT/installer.nix"; then
  echo "Unresolved placeholders remain in $OUT/installer.nix:" >&2
  grep -Eo '__[A-Z0-9_]+__' "$OUT/installer.nix" | sort -u >&2
  die "Refusing to build an ISO with unresolved placeholders."
fi

if [[ "$AUTH_MODE" == "password" ]]; then
  grep -Fq 'settings.PasswordAuthentication = true;' "$OUT/installer.nix" ||
    die "Preflight failed: SSH password authentication setting is missing."

  hash_count="$(grep -F -c "$PASSWORD_HASH" "$OUT/installer.nix" || true)"
  [[ "$hash_count" -eq 2 ]] ||
    die "Preflight failed: expected password hash exactly twice (installer + installed system), found $hash_count."

  if grep -Fq 'openssh.authorizedKeys.keys' "$OUT/installer.nix"; then
    die "Preflight failed: SSH-key configuration unexpectedly remains in password mode."
  fi
else
  key_count="$(grep -F -c "$TF_VAR_PROXMOX_VM_PUBLIC_KEY" "$OUT/installer.nix" || true)"
  [[ "$key_count" -eq 2 ]] ||
    die "Preflight failed: expected SSH public key exactly twice (installer + installed system), found $key_count."

  if grep -Fq 'hashedPassword =' "$OUT/installer.nix"; then
    die "Preflight failed: password configuration unexpectedly remains in SSH-key mode."
  fi
fi

# The previous password bug was caused by constructing configuration.nix in a
# runtime heredoc.  Refuse to proceed if such a heredoc is ever reintroduced.
if grep -Fq 'cat > /mnt/etc/nixos/configuration.nix' "$OUT/installer.nix"; then
  die "Preflight failed: runtime configuration.nix heredoc detected."
fi

grep -Fq '${bootstrapConfig} /mnt/etc/nixos/configuration.nix' "$OUT/installer.nix" ||
  die "Preflight failed: bootstrap configuration copy step is missing."

info "Generated installer.nix passed preflight checks."

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

Authentication:
- Mode: ${AUTH_MODE_DESC}
- Username: ${USER_NAME}
EOF

if [[ "$AUTH_MODE" == "password" ]]; then
  cat >>"$OUT/README.md" <<'EOF'
- SSH password authentication is enabled.
- Only a yescrypt password hash is embedded; the plaintext password is not written to the generated files.
EOF
else
  cat >>"$OUT/README.md" <<'EOF'
- SSH public-key authentication is configured from TF_VAR_PROXMOX_VM_PUBLIC_KEY.
EOF
fi

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

# -----------------------------------------------------------------------------
# OPTIONAL: write built ISO to a removable USB disk (DANGEROUS)
# -----------------------------------------------------------------------------

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}
for c in lsblk dd wipefs findmnt blkid readlink awk sed; do
  require_cmd "$c"
done

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
    read -r -p "$prompt (e.g. /dev/sdb): " dev
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
echo "  ISO -> $ISO_PATH"
echo "  USB -> $USB_DISK"
echo

read -r -p "Type 'YES' to continue: " c1
[[ "$c1" == "YES" ]] || die "Aborted"

read -r -p "Re-type USB disk ($USB_DISK) to confirm: " c2
[[ "$c2" == "$USB_DISK" || "/dev/$c2" == "$USB_DISK" ]] || die "Mismatch"

read -r -p "Type exactly: WIPE $USB_DISK : " c3
[[ "$c3" == "WIPE $USB_DISK" ]] || die "Mismatch"

info "Wiping filesystem signatures..."
$SUDO wipefs -a "$USB_DISK"

info "Writing ISO to USB..."
$SUDO dd if="$ISO_PATH" of="$USB_DISK" bs=4M status=progress conv=fsync

$SUDO sync
info "Done. USB stick is ready."

info "Post-write blkid (best-effort):"
$SUDO blkid "$USB_DISK" || true
