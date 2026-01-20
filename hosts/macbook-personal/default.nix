# Personal MacBook configuration
{ pkgs, username, ... }:

{
  imports = [
    (import ../macbook/base.nix {
      inherit pkgs username;
      extraBrewCasks = [ "gog-galaxy" ];
    })
  ];

  home-manager.users.${username} =
    { pkgs, lib, ... }:
    {
      imports = [ ../../home/generic.nix ];
      _module.args.username = username;
      _module.args.darwinTarget = "macbook-personal";

      home.packages = [
        pkgs.jellyfin
        pkgs.rqbit
      ];

      home.activation.createJellyfinDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p ~/.local/share/jellyfin/log
        $DRY_RUN_CMD mkdir -p ~/.cache/jellyfin
      '';

      launchd.agents.jellyfin = {
        enable = true;
        config = {
          Label = "org.jellyfin.server";
          ProgramArguments = [
            "${pkgs.jellyfin}/bin/jellyfin"
            "--datadir"
            "/Users/${username}/.local/share/jellyfin"
            "--cachedir"
            "/Users/${username}/.cache/jellyfin"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/Users/${username}/.local/share/jellyfin/log/stdout.log";
          StandardErrorPath = "/Users/${username}/.local/share/jellyfin/log/stderr.log";
        };
      };
    };
}
