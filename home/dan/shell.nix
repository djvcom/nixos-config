{ pkgs, lib, isPersonal ? true, ... }:

let
  inherit (pkgs.stdenv) isDarwin isLinux;
  darwinTarget = if isPersonal then "macbook-personal" else "macbook-work";

  # Shared aliases for both bash and zsh
  sharedAliases = {
    la = "ls -lah";
    ls = "eza";
    ll = "eza -l";
    cat = "bat --plain";
    vim = "nvim";
    web = "open '/Applications/Nix Apps/LibreWolf.app'";
    top = "btm";
    du = "dust";
    ps = "procs";
    g = "git";
    gst = "git status";
    ga = "git add";
    gaa = "git add --all";
    gc = "git commit";
    gcm = "git commit -m";
    gco = "git checkout";
    gp = "git push";
    gl = "git pull";
    gd = "git diff";
    gds = "git diff --staged";
    gb = "git branch";
    glog = "git log --oneline --graph --decorate";
    tree = "eza --tree";
  }
  // lib.optionalAttrs isLinux {
    rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#terminus";
  }
  // lib.optionalAttrs isDarwin {
    rebuild = "sudo darwin-rebuild switch --flake ~/.config/nix-darwin#${darwinTarget} --impure";
  };
in
{
  programs = {
    bash = {
      enable = true;
      enableCompletion = true;
      initExtra = ''
        # Source home-manager session vars for SSH sessions
        if [ -f "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ]; then
          . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
        fi

        export PATH="$HOME/.local/bin:$PATH"

        if [ -f "$HOME/.cargo/env" ]; then
          . "$HOME/.cargo/env"
        fi

        # Source local config (not tracked by git)
        if [ -f "$HOME/.localrc" ]; then
          . "$HOME/.localrc"
        fi

        # Source work-specific config if present
        if [ -f "$HOME/.config/shell/work.sh" ]; then
          . "$HOME/.config/shell/work.sh"
        fi
      '';
      shellAliases = sharedAliases;
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autocd = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      initContent = ''
        export PATH="$HOME/.local/bin:$PATH"

        if [ -f "$HOME/.cargo/env" ]; then
          . "$HOME/.cargo/env"
        fi

        # Source local config (not tracked by git)
        if [ -f "$HOME/.localrc" ]; then
          . "$HOME/.localrc"
        fi

        # Source work-specific config if present
        if [ -f "$HOME/.config/shell/work.sh" ]; then
          . "$HOME/.config/shell/work.sh"
        fi
      '';
      shellAliases = sharedAliases;
    };

    zellij = lib.mkIf isLinux {
      enable = true;
      enableBashIntegration = false;
    };

    starship = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;
        character = {
          success_symbol = "[❯](green)";
          error_symbol = "[❯](red)";
        };
        directory.truncation_length = 3;
        git_branch.symbol = " ";
        rust.symbol = " ";
        nodejs.symbol = " ";
        package.disabled = true;
      };
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
}
