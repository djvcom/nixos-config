{
  description = "NixOS configuration for personal infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dagger = {
      url = "github:djvcom/dagger-nix/fix/deprecated-system-attribute";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    djv = {
      url = "github:djvcom/djv/stable";
      # Don't follow nixpkgs - djv needs specific wasm-bindgen-cli version
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      agenix,
      disko,
      dagger,
      djv,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Overlays for package customisation
      overlays = [
        (import ./overlays/vaultwarden-sso.nix)
      ];

      # Helper for creating NixOS configurations
      mkHost =
        hostname:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = overlays; }
            ./hosts/${hostname}
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            disko.nixosModules.disko
            djv.nixosModules.default
            (
              { pkgs, ... }:
              {
                environment.systemPackages = [
                  agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
                  dagger.packages.${pkgs.stdenv.hostPlatform.system}.dagger
                ];
              }
            )
          ];
        };
    in
    {
      nixosConfigurations.terminus = mkHost "terminus";

      # Formatter for `nix fmt`
      formatter.${system} = pkgs.nixfmt-rfc-style;

      # Checks for CI
      checks.${system} = {
        terminus = self.nixosConfigurations.terminus.config.system.build.toplevel;
      };

      # Development shell for working on this repo
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nil
          nixfmt-rfc-style
          agenix.packages.${system}.default
        ];
      };
    };
}
