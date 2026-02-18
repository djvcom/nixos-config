{ inputs, ... }:

{
  flake.nixosConfigurations.terminus = inputs.self.lib.mkNixos {
    hostname = "terminus";
  };
}
