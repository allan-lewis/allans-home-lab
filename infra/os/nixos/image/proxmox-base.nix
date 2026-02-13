{ config, pkgs, lib, ... }:

{
  services.openssh.enable = true;

  services.qemuGuest.enable = true;

  services.cloud-init.enable = true;

  # ✅ critical for Proxmox ipconfig0 → static IP
  services.cloud-init.network.enable = true;
  networking.useNetworkd = true;
  networking.useDHCP = false;

  # --- Automation-friendly sudo bootstrap ---
  users.users.lab = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    curl
    git
    python3
  ];

  system.stateVersion = "24.05";
}

