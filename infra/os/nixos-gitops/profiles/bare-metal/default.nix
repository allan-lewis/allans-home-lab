{ ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.interfaces.eth1.ipv4.addresses = [
    {
      address = "192.168.86.219";
      prefixLength = 24;
    }
  ];

  networking.defaultGateway = {
    address = "192.168.86.1";
    interface = "eth1";
  };

  networking.nameservers = [ "192.168.86.1" ];
  networking.useNetworkd = false;
  networking.useDHCP = false;

  users.users.lab.openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD3nb9sd2O16pH5e/4H9r0SYAPOFVwOsqY9LQSAy5beCXHiTMb4cvCppVySjL9DlOWOAAkjRNlCOkWbJopo6c+AJ3Z8U9WwtBmjjbxrlwcYIJQZRBiVhjFsBEokQGnLlw9nETk0wHleab/15Hve/Uj1tJl7wKIV5ZgrrZxfcaGA4h1PlJmry5wAom2ul294kbR8ZZvPm3qHkMP1GBvAgbexPjkU9TlJ9tb9zX+TNCt4+UDsFBT0B6zGzy3ZufBBShtS3VjUV9LERl4W3OdYurPACZNcPC4T1Wkg05NfOJvE26l/o0CT/fRbU3hwb80H4ZbcWTeQ32PuQY+3DxQXs66ywzfTaSuL9tAPjLFhG6xzCrRsw9YceZ4xk/k+snFItKyfqzOVL2tpZMT8gB8TAqSN89jyG0/Z+dFlL0aAGSVvsHfnQ3ALf4wsikfS63cylc7hlYymBETFFYzOF3APxyWZgZXlCDisKUitbBubNYbLxvDVrSFuGfrUXXclFDb1RTOEZLAtfPxOlvqMqo5srmlg42//hxkjHIWwsZxG7p2n2wk/MunraHp4367ciyPZZzLKLSVXnYBZf78WKrgE3RgjhUReZ9xdmGtzip6pAZ/VKv8neP+CP2ZubsySa/dFOHFseSeAGVnF92gpKfNVG34hR+CAWMFA3yVbKJLvtX6jww==" ];
}