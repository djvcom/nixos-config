# Shell configuration (bash, zsh, starship, direnv, etc.)
_:

{
  flake.modules.homeManager.shell =
    {
      pkgs,
      lib,
      darwinTarget ? "macbook-personal",
      ...
    }:
    let
      inherit (pkgs.stdenv) isDarwin isLinux;

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
        rebuild = "sudo nixos-rebuild switch --flake ~/.config/nixos#$(hostname)";
        sleep = "systemctl suspend";
        shutdown = "systemctl poweroff";
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

            # Homebrew shell environment (macOS)
            if [ -x /opt/homebrew/bin/brew ]; then
              eval "$(/opt/homebrew/bin/brew shellenv)"
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
            # Homebrew shell environment (macOS)
            if [ -x /opt/homebrew/bin/brew ]; then
              eval "$(/opt/homebrew/bin/brew shellenv)"
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

        readline = {
          enable = true;
          extraConfig = ''
            # Up/down arrows search history based on typed prefix
            "\e[A": history-search-backward
            "\e[B": history-search-forward
          '';
        };
      };
    };
}
