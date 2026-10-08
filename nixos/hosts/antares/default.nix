{ hostName, nixosVersion, ... }:

{
  imports = [
    ../../modules/virtual-machine

    ../../profiles/tautulli
  ];

  networking.hostName = hostName;
  system.stateVersion = nixosVersion;
}

