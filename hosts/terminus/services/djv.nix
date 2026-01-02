# djv portfolio site with PostgreSQL database
_:

{
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
}
