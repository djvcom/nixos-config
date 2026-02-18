{ inputs, ... }:

{
  flake.nixosConfigurations.oshun = inputs.self.lib.mkNixos {
    hostname = "oshun";
  };
}
