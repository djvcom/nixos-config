# Work MacBook configuration
{ pkgs, username, ... }:

{
  imports = [
    (import ../macbook/base.nix {
      inherit pkgs username;
      extraBrewCasks = [];
    })
  ];

  # Home-manager configuration for the current user
  home-manager.users.${username} =
    { ... }:
    {
      imports = [ ../../home/generic.nix ];
      _module.args.username = username;
      _module.args.isPersonal = false;

      # Work-specific packages
      home.packages = with pkgs; [
        uv
      ];
    };
}
