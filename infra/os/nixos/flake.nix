{
  description = "NixOS Proxmox base template image (qcow2) for Allan's homelab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-generators }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.proxmox-base = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./image/proxmox-base.nix
        ];
      };

      # NOTE: nixos-generators calls the qcow2 format "qcow"
      packages.${system}.proxmox-base-qcow2 =
        nixos-generators.nixosGenerate {
          inherit system;
          format = "qcow";
          modules = [
            ./image/proxmox-base.nix
          ];
        };
    };
}

