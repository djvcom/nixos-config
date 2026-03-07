{ inputs, ... }:

{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      basePkgs =
        if system == "aarch64-darwin" then inputs.nixpkgs-darwin.legacyPackages.${system} else pkgs;
    in
    {
      devShells.default = basePkgs.mkShell {
        packages =
          with basePkgs;
          [
            nil
            nixfmt
            nix-tree
            nh
            inputs.agenix.packages.${system}.default
          ]
          ++ config.pre-commit.settings.enabledPackages;
        shellHook = config.pre-commit.installationScript;
      };
    };
}
