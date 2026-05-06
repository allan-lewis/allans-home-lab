{ ... }:

{
  imports = [
    ../../_modules/openvpn-client
    ../../_modules/vpn-kill-switch
  ];

  sops.secrets.openvpn-auth = {
    sopsFile = ./openvpn.yaml;
    key = "auth.txt";
    path = "/run/secrets/openvpn/auth.txt";
    owner = "root";
    group = "root";
    mode = "0600";
  };

  sops.secrets.openvpn-client-crt = {
    sopsFile = ./openvpn.yaml;
    key = "client.crt";
    path = "/run/secrets/openvpn/client.crt";
    owner = "root";
    group = "root";
    mode = "0600";
  };

  sops.secrets.openvpn-client-key = {
    sopsFile = ./openvpn.yaml;
    key = "client.key";
    path = "/run/secrets/openvpn/client.key";
    owner = "root";
    group = "root";
    mode = "0600";
  };

  sops.secrets.openvpn-tls-auth = {
    sopsFile = ./openvpn.yaml;
    key = "tls-auth.key";
    path = "/run/secrets/openvpn/tls-auth.key";
    owner = "root";
    group = "root";
    mode = "0600";
  };

  sops.secrets.openvpn-ca-crt = {
    sopsFile = ./openvpn.yaml;
    key = "ca.crt";
    path = "/run/secrets/openvpn/ca.crt";
    owner = "root";
    group = "root";
    mode = "0444";
  };

  services.homelab.openvpnClient = {
    enable = true;
    name = "expressvpn";
    configFile = ./client.conf;
    restartDaily = true;
    restartTime = "06:00";
  };

  services.homelab.vpnKillSwitch = {
    enable = true;

    wanInterface = "eth0";
    vpnInterface = "tun0";

    lanSubnets = [ "192.168.86.0/24" ];

    vpnEndpointIps = [
      "45.84.216.183"
      "45.84.216.83"
    ];

    vpnPort = 1195;
    vpnProtocol = "udp";
  };

  systemd.services.openvpn-expressvpn = {
    after = [ "network-online.target" "nftables.service" ];
    wants = [ "network-online.target" ];
    requires = [ "nftables.service" ];
  };
}