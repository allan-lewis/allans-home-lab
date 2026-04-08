{ ... }:

{
  imports = [
    ../../modules/openvpn-client.nix
  ];

  sops.secrets.openvpn-auth = {
    sopsFile = ../../secrets/openvpn.yaml;
    key = "auth.txt";
    path = "/run/secrets/openvpn/auth.txt";
    owner = "root";
    group = "root";
    mode = "0600";
  };

  sops.secrets.openvpn-client-crt = {
    sopsFile = ../../secrets/openvpn.yaml;
    key = "client.crt";
    path = "/run/secrets/openvpn/client.crt";
    owner = "root";
    group = "root";
    mode = "0600";
  };

  sops.secrets.openvpn-client-key = {
    sopsFile = ../../secrets/openvpn.yaml;
    key = "client.key";
    path = "/run/secrets/openvpn/client.key";
    owner = "root";
    group = "root";
    mode = "0600";
  };

  sops.secrets.openvpn-tls-auth = {
    sopsFile = ../../secrets/openvpn.yaml;
    key = "tls-auth.key";
    path = "/run/secrets/openvpn/tls-auth.key";
    owner = "root";
    group = "root";
    mode = "0600";
  };

  sops.secrets.openvpn-ca-crt = {
    sopsFile = ../../secrets/openvpn.yaml;
    key = "ca.crt";
    path = "/run/secrets/openvpn/ca.crt";
    owner = "root";
    group = "root";
    mode = "0644";
  };

  services.homelab.openvpnClient = {
    enable = true;
    name = "expressvpn";
    configFile = ../../assets/openvpn/expressvpn/client.conf;
    restartDaily = true;
    restartTime = "06:00";
  };
}