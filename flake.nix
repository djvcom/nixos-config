{
  description = "NixOS and nix-darwin configuration for personal infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Use nixpkgs-unstable for darwin (matches nixos-unstable packages)
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

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
      nixpkgs-darwin,
      nix-darwin,
      home-manager,
      agenix,
      disko,
      dagger,
      djv,
      ...
    }@inputs:
    let
      # Overlays for package customisation (Linux-specific)
      linuxOverlays = [
        (import ./overlays/vaultwarden-sso.nix)
        (import ./overlays/kanidm-csp.nix)
        (import ./overlays/opentelemetry-collector.nix)
      ];

      # Helper for creating NixOS configurations
      mkNixosHost =
        hostname:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = linuxOverlays; }
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

      # Helper for creating nix-darwin configurations
      mkDarwinHost =
        {
          hostname,
          system ? "aarch64-darwin",
        }:
        let
          # When run with sudo, SUDO_USER contains the original username
          # When run without sudo, fall back to USER
          sudoUser = builtins.getEnv "SUDO_USER";
          user = builtins.getEnv "USER";
          username =
            if sudoUser != "" then
              sudoUser
            else if user != "" then
              user
            else
              builtins.throw "Could not determine username from SUDO_USER or USER environment variables";
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs username;
          };
          modules = [
            ./hosts/${hostname}
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
              };
            }
          ];
        };
    in
    {
      # NixOS configurations
      nixosConfigurations.terminus = mkNixosHost "terminus";

      # nix-darwin configurations
      # Usage: darwin-rebuild switch --flake .#macbook
      darwinConfigurations.macbook = mkDarwinHost { hostname = "macbook"; };

      # Formatter for `nix fmt`
      formatter = {
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
        aarch64-darwin = nixpkgs-darwin.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
      };

      # Checks for CI
      checks.x86_64-linux = {
        terminus = self.nixosConfigurations.terminus.config.system.build.toplevel;
      };

      # Development shell for working on this repo
      devShells = {
        x86_64-linux =
          let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
          in
          {
            default = pkgs.mkShell {
              packages = with pkgs; [
                nil
                nixfmt-rfc-style
                agenix.packages.x86_64-linux.default
              ];
            };
          };
        aarch64-darwin =
          let
            pkgs = nixpkgs-darwin.legacyPackages.aarch64-darwin;
          in
          {
            default = pkgs.mkShell {
              packages = with pkgs; [
                nil
                nixfmt-rfc-style
              ];
            };
          };
      };
    };
}
