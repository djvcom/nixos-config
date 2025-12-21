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
      url = "github:dagger/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nginx-otel = {
      url = "github:djvcom/nix-nginx-otel";
      inputs.nixpkgs.follows = "nixpkgs";
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
      nginx-otel,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Helper for creating NixOS configurations
      mkHost =
        hostname:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${hostname}
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            disko.nixosModules.disko
            nginx-otel.nixosModules.default
            {
              environment.systemPackages = [
                agenix.packages.${system}.default
                dagger.packages.${system}.dagger
              ];
            }
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
