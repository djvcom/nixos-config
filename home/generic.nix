# Shared home-manager configuration for all machines
# Username is passed via _module.args from each host config
{
  pkgs,
  lib,
  username,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin isLinux;
in
{
  imports = [
    ./modules/neovim.nix
    ./modules/shell.nix
    ./modules/git.nix
    ./modules/gitlab.nix
    ./modules/ghostty.nix
    ./modules/firefox.nix
    ./modules/aerospace.nix
  ];

  home = {
    inherit username;
    homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";
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

        # Modern CLI tools
        bat
        delta
        fzf
        bottom
        dust
        procs
        sd
        hyperfine
        tokei

        # Nix tooling
        nil # LSP
        nixfmt
        statix # Linter
        deadnix # Find unused code
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
}
