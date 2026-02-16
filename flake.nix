{
  description = "NixOS and nix-darwin configuration for personal infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Use nixpkgs-unstable for darwin (matches nixos-unstable packages)
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    import-tree.url = "github:vic/import-tree";

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

    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      inherit (inputs.import-tree ./modules) imports;
    };
}
