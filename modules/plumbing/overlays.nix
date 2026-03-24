{ inputs, ... }:

{
  flake.overlays = {
    vaultwarden-sso = import ../../overlays/vaultwarden-sso.nix;
    garage-v2 = import ../../overlays/garage-v2.nix;
    direnv-cgo = import ../../overlays/direnv-cgo.nix;
    sidereal = inputs.sidereal.overlays.default;
  };
}
