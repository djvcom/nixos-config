# Generic home-manager configuration that accepts username as parameter
# Used for machines where username varies (e.g., work laptop)
{
  pkgs,
  username,
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
  ];

  home = {
    inherit username;
    homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";
    packages = with pkgs; [
      ripgrep
      fd
      eza
      jq
      gh
      glab
      rustup
      gcc
      yarn
      nodePackages.typescript-language-server
      dnsutils

      # Nix tooling
      nil # LSP
      nixfmt-rfc-style # Formatter (official nixpkgs standard)
      statix # Linter
      deadnix # Find unused code
    ];
    sessionVariables = {
      EDITOR = "nvim";
    };
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
