{ pkgs, ... }:

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
    username = "dan";
    homeDirectory = if isDarwin then "/Users/dan" else "/home/dan";
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

      # Modern CLI tools
      delta

      # Nix tooling
      nil # LSP
      nixfmt
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
