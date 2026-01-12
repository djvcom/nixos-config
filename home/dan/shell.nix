{ pkgs, lib, ... }:

let
  inherit (pkgs.stdenv) isDarwin isLinux;
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
      '';
      shellAliases = {
        la = "ls -lah";
        vim = "nvim";
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
      // lib.optionalAttrs (!isDarwin) {
        rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#terminus";
      }
      // lib.optionalAttrs isDarwin {
        rebuild = "darwin-rebuild switch --flake ~/.config/nix-darwin#macbook";
      };
    };

    zellij = lib.mkIf isLinux {
      enable = true;
      enableBashIntegration = false;
    };

    starship = {
      enable = true;
      enableBashIntegration = true;
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
      nix-direnv.enable = true;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
    };
  };
}
