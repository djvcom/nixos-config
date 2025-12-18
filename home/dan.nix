{ config, pkgs, lib, ... }:

{
  imports = [
    ./dan/neovim.nix
    ./dan/shell.nix
    ./dan/git.nix
  ];

  home.username = "dan";
  home.homeDirectory = "/home/dan";

  home.packages = with pkgs; [
    ripgrep
    fd
    eza
    jq
    gh
    rustup
    gcc
    yarn
    nodePackages.typescript-language-server
  ];

  home.sessionVariables = {
    DOCKER_HOST = "unix:///run/podman/podman.sock";
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
