{ inputs, ... }:

{
  flake.overlays = {
    vaultwarden-sso = import ../../overlays/vaultwarden-sso.nix;
    opentelemetry-collector = import ../../overlays/opentelemetry-collector.nix;
    garage-v2 = import ../../overlays/garage-v2.nix;
    uvloop-skip-ssl-test = import ../../overlays/uvloop-skip-ssl-test.nix;
    sidereal = inputs.sidereal.overlays.default;
  };
}
