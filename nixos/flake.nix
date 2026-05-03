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
    nasBasePath =
      "allan@192.168.86.220:/mnt/pool1/allans-home-lab/backups-automated";

    versionCurrent = "25.11";
    versionNext = "26.05";

    commonModules = [
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];

    mkHost = hostPath: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit nasBasePath;
        inherit versionCurrent;
        inherit versionNext;
      };
      modules = commonModules ++ [
        (hostPath + "/hardware-configuration.nix")
        (hostPath + "/default.nix")
      ];
    };
  in
  {
    nixosConfigurations = {
      blaine = mkHost ./hosts/blaine;
      carrie = mkHost ./hosts/carrie;
      cujo = mkHost ./hosts/cujo;
      flagg = mkHost ./hosts/flagg;
      langolier = mkHost ./hosts/langolier;
      misery = mkHost ./hosts/misery;
      patricia = mkHost ./hosts/patricia;
      roland = mkHost ./hosts/roland;
      todash = mkHost ./hosts/todash;
    };
  };
}
