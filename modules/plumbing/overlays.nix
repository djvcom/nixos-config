{ inputs, ... }:

{
  flake.overlays = {
    garage-v2 = import ../../overlays/garage-v2.nix;
    sidereal = inputs.sidereal.overlays.default;
  };
}
