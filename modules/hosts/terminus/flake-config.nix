# Register terminus as a NixOS configuration
{ inputs, ... }:

{
  flake.nixosConfigurations.terminus = inputs.self.lib.mkNixos {
    hostname = "terminus";
  };
}
