{ config, pkgs, lib, ... }:

{
  # Minimal, generic base suitable for Proxmox templates:
  # - SSH for access
  # - QEMU guest agent for Proxmox integration
  # - cloud-init so L2 can inject identity/config
  # - flakes enabled so L3 can switch from Git

  services.openssh.enable = true;

  services.qemuGuest.enable = true;

  services.cloud-init.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Small baseline toolset (optional but handy)
  environment.systemPackages = with pkgs; [
    curl
    git
  ];

  # Required: set once and rarely change
  system.stateVersion = "24.05";
}

