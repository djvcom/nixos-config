{ inputs, ... }:

{
  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.git-hooks.flakeModule
  ];

  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];
}
