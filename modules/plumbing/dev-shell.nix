{ inputs, ... }:

{
  perSystem =
    {
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
        packages = with basePkgs; [
          nil
          nixfmt
          deadnix
          statix
          nix-tree
          nh
          just
          pre-commit
          inputs.agenix.packages.${system}.default
        ];
        shellHook = ''
          pre-commit install --allow-missing-config
        '';
      };
    };
}
