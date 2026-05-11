{
  description = "Allan's Homelab - NixOS GitOps fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, sops-nix, ... }:

  let
    system = "x86_64-linux";

    nixosVersion = "25.11";

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
        remoteBackupRoot = 
          "allan@192.168.86.220:/mnt/pool1/allans-home-lab/backups-automated/${actualHostName}";
      in
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit
            hostInterface
            hostIp4Address
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
      blaine = mkHost "blaine";
      carrie = mkHost "carrie";
      cujo = mkHost "cujo";
      flagg = mkHost "flagg";
      langolier = mkHost "langolier";
      misery = mkHost "misery";
      patricia = mkHost "patricia";
      roland = mkHost "roland";
      todash = mkHost "todash";
    };
  };
}