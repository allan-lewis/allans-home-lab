{
  description = "Allan's Homelab - NixOS GitOps fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, sops-nix, ... }:

  let
    system = "x86_64-linux";

    nixosVersion = "26.05";

    commonModules = [
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];

    mkHost = hostName:
      let
        hostPath = ./hosts/${hostName};

        inventoryConfig =
          builtins.fromTOML (
            builtins.readFile ../inventory/hosts/${hostName}.toml
          );

        actualHostName = inventoryConfig.hostname;
        hostInterface = inventoryConfig.network.interface;
        hostIp4Address = inventoryConfig.network.ipv4.address;
        hostIp4Gateway = inventoryConfig.network.ipv4.gateway;
        hostDns = inventoryConfig.network.dns;
        remoteBackupRoot = 
          "allan@polaris.ip.allanshomelab.com:/mnt/pool1/allans-home-lab/backups-automated/${actualHostName}";
      in
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit
            hostDns
            hostInterface
            hostIp4Address
            hostIp4Gateway
            remoteBackupRoot
            nixosVersion
            ;

          hostName = actualHostName;
        };

        modules = commonModules ++ [
          (hostPath + "/hardware-configuration.nix")
          (hostPath + "/default.nix")
        ];
      };
  in
  {
    nixosConfigurations = {
      capella = mkHost "capella";
      bellatrix = mkHost "bellatrix";
      blaine = mkHost "blaine";
      carrie = mkHost "carrie";
      castor = mkHost "castor";
      cujo = mkHost "cujo";
      flagg = mkHost "flagg";
      misery = mkHost "misery";
      regulus = mkHost "regulus";
      pollux = mkHost "pollux";
      roland = mkHost "roland";
      todash = mkHost "todash";
    };
  };
}
