{ inputs, ... }:

{
  flake.modules.nixos.agenix = {
    imports = [ inputs.agenix.nixosModules.default ];
    environment.systemPackages = [
      inputs.agenix.packages.x86_64-linux.default
    ];
  };

  flake.modules.darwin.agenix = {
    imports = [ inputs.agenix.darwinModules.default ];
    environment.systemPackages = [
      inputs.agenix.packages.aarch64-darwin.default
    ];
  };
}
