{
  description = "Allan's Homelab - NixOS GitOps fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    home-manager-unstable.url = "github:nix-community/home-manager/master";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix-unstable.url = "github:Mic92/sops-nix";
    sops-nix-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, home-manager-unstable, sops-nix, sops-nix-unstable, ... }:

  let
    system = "x86_64-linux";

    nixosVersion = "26.05";

    mkHost = hostName:
      { nixpkgsFlake ? nixpkgs
      , homeManagerFlake ? home-manager
      , sopsNixFlake ? sops-nix
      , hostNixosVersion ? nixosVersion
      }:
      let
        commonModules = [
          homeManagerFlake.nixosModules.home-manager
          sopsNixFlake.nixosModules.sops
        ];

        hostPath = ./hosts/${hostName};

        inventoryConfig =
          builtins.fromTOML (
            builtins.readFile ../inventory/hosts/${hostName}.toml
          );

        defaultSubnet = "192.168.10.0/24";
        defaultNasHost = "polaris.ip.allanshomelab.com";
        authentikHost = "castor.ip.allanshomelab.com";
        actualHostName = inventoryConfig.hostname;
        hostInterface = inventoryConfig.network.interface;
        hostIp4Address = inventoryConfig.network.ipv4.address;
        hostIp4Gateway = inventoryConfig.network.ipv4.gateway;
        hostDns = inventoryConfig.network.dns;
        remoteBackupRoot = 
          "allan@${defaultNasHost}:/mnt/pool1/allans-home-lab/backups-automated/${actualHostName}";
      in
      nixpkgsFlake.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit
            defaultSubnet
            defaultNasHost
            authentikHost
            hostDns
            hostInterface
            hostIp4Address
            hostIp4Gateway
            remoteBackupRoot
            ;

          nixosVersion = hostNixosVersion;
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
      antares = mkHost "antares" { };
      capella = mkHost "capella" { };
      bellatrix = mkHost "bellatrix" { };
      castor = mkHost "castor" { };
      regulus = mkHost "regulus" { };
      pollux = mkHost "pollux" { };
      deneb = mkHost "deneb" {
        nixpkgsFlake = nixpkgs-unstable;
        homeManagerFlake = home-manager-unstable;
        sopsNixFlake = sops-nix-unstable;
        hostNixosVersion = "26.11";
      };
    };
  };
}
