{ ... }:

{
  imports = [
    ../base
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.useNetworkd = true;
  networking.useDHCP = false;

  services.qemuGuest.enable = true;
  services.cloud-init.enable = true;
  services.cloud-init.network.enable = true;
}