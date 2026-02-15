# Base home-manager configuration shared across all machines
_:

{
  flake.modules.homeManager.base =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv) isDarwin isLinux;
    in
    {
      home = {
        packages =
          with pkgs;
          [
            ripgrep
            fd
            eza
            jq
            gh
            glab
            rustup
            gcc
            libiconv
            nodejs_24
            yarn
            nodePackages.typescript-language-server
            dnsutils

            bat
            delta
            fzf
            bottom
            dust
            procs
            sd
            hyperfine
            tokei

            nil
            nixfmt
            statix
            deadnix
          ]
          ++ lib.optionals isLinux [
            chromium
          ];
        sessionVariables = {
          EDITOR = "nvim";
        }
        // lib.optionalAttrs isDarwin {
          LIBRARY_PATH = "${pkgs.libiconv}/lib";
          NIX_LDFLAGS = "-L${pkgs.libiconv}/lib";
        };
        stateVersion = "25.05";
      };

      programs.home-manager.enable = true;

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks."*" = {
          extraOptions = {
            AddKeysToAgent = "yes";
          }
          // lib.optionalAttrs isDarwin {
            UseKeychain = "yes";
          };
        };
      };
    };
}
