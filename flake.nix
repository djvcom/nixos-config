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

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    sidereal = {
      url = "github:djvcom/sidereal";
      # Don't follow nixpkgs - sidereal needs rust-overlay
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
      sidereal,
      ...
    }@inputs:
    let
      # Overlays for package customisation (Linux-specific)
      linuxOverlays = [
        (import ./overlays/vaultwarden-sso.nix)
        (import ./overlays/kanidm-csp.nix)
        (import ./overlays/opentelemetry-collector.nix)
        (import ./overlays/garage-v2.nix)
        sidereal.overlays.default
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
            sidereal.nixosModules.sidereal
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
            agenix.darwinModules.default
            (
              { pkgs, ... }:
              {
                environment.systemPackages = [
                  agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
                ];
              }
            )
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs username; };
              };
            }
          ];
        };
    in
    {
      # NixOS configurations
      nixosConfigurations.terminus = mkNixosHost "terminus";

      # nix-darwin configurations
      darwinConfigurations = {
        macbook-personal = mkDarwinHost { hostname = "macbook-personal"; };
        macbook-work = mkDarwinHost { hostname = "macbook-work"; };
        # Alias for backwards compatibility
        macbook = mkDarwinHost { hostname = "macbook-personal"; };
      };

      # Formatter for `nix fmt`
      formatter = {
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
        aarch64-darwin = nixpkgs-darwin.legacyPackages.aarch64-darwin.nixfmt;
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
                nixfmt
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
                nixfmt
                agenix.packages.aarch64-darwin.default
              ];
            };
          };
      };
    };
}
