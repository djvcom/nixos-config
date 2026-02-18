{ inputs, ... }:

{
  flake.modules.darwin.macbook-work =
    { username, ... }:
    {
      imports = with inputs.self.modules.darwin; [
        agenix
        home-manager
        base
        zscaler
      ];

      homebrew.brews = [
        "opencode"
        "dagger"
      ];

      home-manager.users.${username} =
        { pkgs, ... }:
        {
          imports = with inputs.self.modules.homeManager; [
            base
            shell
            git
            neovim
            firefox
            ghostty
            aerospace
            gitlab
          ];
          _module.args.darwinTarget = "macbook-work";

          home = {
            inherit username;
            homeDirectory = "/Users/${username}";

            packages = with pkgs; [
              uv
              aws-sam-cli
              awscli2
              zig
              opentofu
              terraform-ls
              tflint
            ];

            # Work-specific shell config
            file.".config/shell/work.sh" = {
              executable = true;
              text = ''
                export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
                export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
                export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
                export AWS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

                export CC=/usr/bin/clang
                export RUSTFLAGS="-C linker=/usr/bin/clang"

                # glab config location varies - check both possible paths
                _glab_config=""
                if [ -f "$HOME/.config/glab-cli/config.yml" ]; then
                  _glab_config="$HOME/.config/glab-cli/config.yml"
                elif [ -f "$HOME/Library/Application Support/glab-cli/config.yml" ]; then
                  _glab_config="$HOME/Library/Application Support/glab-cli/config.yml"
                elif [ -f "$HOME/Library/Application Support/glab-cli/config.yaml" ]; then
                  _glab_config="$HOME/Library/Application Support/glab-cli/config.yaml"
                fi

                if [ -n "$_glab_config" ]; then
                  _gitlab_token=$(grep -A20 "hosts:" "$_glab_config" 2>/dev/null | grep "token:" | head -1 | sed 's/.*token: //' | sed 's/!!null //')
                  if [ -n "$_gitlab_token" ] && [ "$_gitlab_token" != "null" ]; then
                    export GITLAB_TOKEN="$_gitlab_token"
                    export NPM_TOKEN="$_gitlab_token"
                  fi
                  unset _gitlab_token
                fi
                unset _glab_config
              '';
            };
          };
        };
    };
}
