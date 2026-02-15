# Formatter for `nix fmt`
{ inputs, ... }:

{
  perSystem =
    { pkgs, system, ... }:
    {
      formatter =
        if system == "aarch64-darwin" then
          inputs.nixpkgs-darwin.legacyPackages.${system}.nixfmt
        else
          pkgs.nixfmt;
    };
}
