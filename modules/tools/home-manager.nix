# Home-manager integration for NixOS and Darwin
{ inputs, ... }:

{
  flake.modules.nixos.home-manager = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
    };
  };

  flake.modules.darwin.home-manager =
    { username, ... }:
    {
      imports = [ inputs.home-manager.darwinModules.home-manager ];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = {
          inherit inputs username;
        };
      };
    };
}
