{
  description = "Allan's Homelab - GitOps experiment for todash";

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
  in
  {
    nixosConfigurations.todash = nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops

        ./hosts/todash/hardware-configuration.nix
        ./modules/backup-runner.nix
        ./modules/dev-checkouts.nix
        ./modules/doppler.nix
        ./modules/homelab-hello.nix
        ./modules/homelab-tasks.nix
        ./modules/managed-directories.nix
        ./modules/postgres-db-backup.nix
        ./modules/s3-local-mirror.nix

        ./hosts/todash/default.nix
      ];
    };
  };
}