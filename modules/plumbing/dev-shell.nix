# Development shell for working on this repo
{ inputs, ... }:

{
  perSystem =
    { pkgs, system, ... }:
    let
      basePkgs =
        if system == "aarch64-darwin" then inputs.nixpkgs-darwin.legacyPackages.${system} else pkgs;
    in
    {
      devShells.default = basePkgs.mkShell {
        packages = with basePkgs; [
          nil
          nixfmt
          inputs.agenix.packages.${system}.default
        ];
      };
    };
}
