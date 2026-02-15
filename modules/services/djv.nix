# djv portfolio site with PostgreSQL database
{ inputs, ... }:

{
  flake.modules.nixos.djv = {
    imports = [ inputs.djv.nixosModules.default ];

    services.djv = {
      enable = true;
      environment = "production";
      listenAddress = "127.0.0.1:7823";
      database.enable = true;
      sync = {
        enable = true;
        github.user = "djvcom";
        cratesIo.user = "djvcom";
        npm.user = "djverrall";
        gitlab.user = "djverrall";
      };
    };
  };
}
