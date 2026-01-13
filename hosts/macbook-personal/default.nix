# Personal MacBook configuration
{ pkgs, username, ... }:

{
  imports = [
    (import ../macbook/base.nix {
      inherit pkgs username;
      extraBrewCasks = [ "gog-galaxy" ];
    })
  ];

  # Home-manager configuration for the current user
  home-manager.users.${username} =
    { ... }:
    {
      imports = [ ../../home/generic.nix ];
      _module.args.username = username;
      _module.args.isPersonal = true;
    };
}
