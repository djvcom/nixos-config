_:

{
  flake.modules.homeManager.cursor =
    { pkgs, lib, ... }:
    {
      home.pointerCursor = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        enable = true;
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
        gtk.enable = true;
      };
    };
}
