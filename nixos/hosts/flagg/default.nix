{ backupRemotePrefix, config, ... }:

let
  hostName = inventoryConfig.hostname;
  backupLocation = "${backupRemotePrefix}/${hostName}";
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/flagg.toml);
in
{
  _module.args = {
    backupRoot = backupLocation;
    hostAddress = inventoryConfig.network.ipv4.address;
    hostInterface = "eth1";
    hostName = hostName;
  };

  imports = [
    ../../profiles/hosts/flagg.nix
  ];

  # imports = [
    # ../../profiles/authentik
    # ../../profiles/s3-mirror
  # ];

  # networking.hostName = hostName;

  # homelab.bareMetal.interface = "eth1";
  # homelab.bareMetal.address = "192.168.86.204";

  system.stateVersion = "25.11";
}