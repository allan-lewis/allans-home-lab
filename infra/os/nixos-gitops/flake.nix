{
  description = "Allan's Homelab - NixOps fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix }:
  let
    system = "x86_64-linux";

    commonModules = [
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops

      ./modules/backup-runner.nix
      ./modules/dev-checkouts.nix
      ./modules/doppler.nix
      ./modules/homelab-hello.nix
      ./modules/homelab-tasks.nix
      ./modules/managed-directories.nix
      ./modules/postgres-db-backup.nix
      ./modules/s3-local-mirror.nix
    ];
  in
  {
    nixosConfigurations = {
      todash = nixpkgs.lib.nixosSystem {
        inherit system;
        modules =
          commonModules
          ++ [
            ./hosts/todash/hardware-configuration.nix
            ./hosts/todash/default.nix
          ];
      };

      cujo = nixpkgs.lib.nixosSystem {
        inherit system;
        modules =
          commonModules
          ++ [
            ./hosts/cujo/hardware-configuration.nix
            ./hosts/cujo/default.nix
          ];
      };
    };
  };
}