# Generic home-manager configuration that accepts username as parameter
# Used for machines where username varies (e.g., work laptop)
{
  pkgs,
  lib,
  username,
  isPersonal ? true,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin;
in
{
  imports = [
    ./dan/neovim.nix
    ./dan/shell.nix
    ./dan/git.nix
    ./dan/gitlab.nix
    ./dan/ghostty.nix
    ./dan/firefox.nix
    ./dan/aerospace.nix
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
      ++ lib.optionals isPersonal [
        jellyfin-media-player
      ];
    sessionVariables = {
      EDITOR = "nvim";
    };
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
