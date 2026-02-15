# Register oshun as a NixOS configuration
{ inputs, ... }:

{
  flake.nixosConfigurations.oshun = inputs.self.lib.mkNixos {
    hostname = "oshun";
  };
}
