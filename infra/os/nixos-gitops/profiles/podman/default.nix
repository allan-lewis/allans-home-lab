{ pkgs, ... }:

{
  virtualisation.podman.enable = true;

  systemd.services.force-ipv4-forwarding = {
    description = "Force IPv4 forwarding on after networking settles";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "NetworkManager.service"
      "systemd-networkd.service"
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.procps}/bin/sysctl -w net.ipv4.ip_forward=1
    '';
  };

}