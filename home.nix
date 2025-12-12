{ config, pkgs, lib, ... }:

{
  home.username = "dan";
  home.homeDirectory = "/home/dan";

  home.packages = with pkgs; [
    ripgrep
    fd
    eza
    jq
    gh
  ];

  home.file.".npm-global/.keep".text = "";

  home.sessionVariables = {
    EDITOR = "vim";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      export PATH="$HOME/.npm-global/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"

      if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
      fi
    '';
    shellAliases = {
      la = "ls -lah";
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#terminus";
    };
  };

  programs.zellij = {
    enable = true;
    enableBashIntegration = false;
  };

  programs.git = {
    enable = true;
    includes = [{
      path = "~/.config/git/identity";
    }];
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
