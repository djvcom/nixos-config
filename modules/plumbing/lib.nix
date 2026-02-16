# Helper functions for creating NixOS and Darwin configurations
{ inputs, ... }:

let
  inherit (inputs) nixpkgs nix-darwin;
in
{
  flake.lib = {
    mkNixos =
      {
        hostname,
        system ? "x86_64-linux",
      }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          { nixpkgs.overlays = inputs.self.lib.linuxOverlays; }
          inputs.self.modules.nixos.${hostname}
        ];
      };

    mkDarwin =
      {
        hostname,
        system ? "aarch64-darwin",
      }:
      let
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
        modules = [
          { _module.args.username = username; }
          inputs.self.modules.darwin.${hostname}
        ];
      };

    linuxOverlays = [
      (import ../../overlays/vaultwarden-sso.nix)
      (import ../../overlays/kanidm-csp.nix)
      (import ../../overlays/opentelemetry-collector.nix)
      (import ../../overlays/garage-v2.nix)
      inputs.sidereal.overlays.default
      (final: _prev: {
        inherit (inputs.awww.packages.${final.stdenv.hostPlatform.system}) awww;
      })
    ];
  };
}
