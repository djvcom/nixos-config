{ inputs, ... }:

{
  flake.modules.darwin.macbook-personal =
    { username, ... }:
    {
      imports = with inputs.self.modules.darwin; [
        agenix
        home-manager
        base
      ];

      age.identityPaths = [ "/Users/${username}/.ssh/id_ed25519" ];
      age.secrets.git-identity = {
        file = ../../../secrets/git-identity.age;
        path = "/Users/${username}/.config/git/identity";
        owner = username;
        group = "staff";
        mode = "0400";
      };

      homebrew.casks = [
        "gog-galaxy"
        "vlc"
      ];

      home-manager.users.${username} =
        { pkgs, lib, ... }:
        {
          imports =
            (with inputs.self.modules.homeManager; [
              base
              shell
              git
              neovim
              firefox
              ghostty
              aerospace
              gitlab
            ])
            ++ [ inputs.sidereal.homeManagerModules.sidereal-ai ];

          services.sidereal-ai = {
            enable = true;
            package = inputs.sidereal.packages.${pkgs.stdenv.hostPlatform.system}.sidereal-ai;
            sidereal.url = "https://sidereal.djv.sh";
            auth.oidc = {
              enable = true;
              issuer = "https://auth.djv.sh/oauth2/openid/sidereal";
              clientId = "sidereal";
            };
          };
          _module.args.darwinTarget = "macbook-personal";

          home = {
            inherit username;
            homeDirectory = "/Users/${username}";

            packages = [
              pkgs.jellyfin
              pkgs.rqbit
            ];

            activation.createJellyfinDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              $DRY_RUN_CMD mkdir -p ~/.local/share/jellyfin/log
              $DRY_RUN_CMD mkdir -p ~/.cache/jellyfin
            '';
          };

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
    };
}
