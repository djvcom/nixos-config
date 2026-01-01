{ pkgs, ... }:

{
  imports = [
    ./dan/neovim.nix
    ./dan/shell.nix
    ./dan/git.nix
    ./dan/gitlab.nix
  ];

  home = {
    username = "dan";
    homeDirectory = "/home/dan";
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
