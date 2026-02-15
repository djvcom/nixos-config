# Import flake-parts module system and define supported systems
{ inputs, ... }:

{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ];

  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];
}
