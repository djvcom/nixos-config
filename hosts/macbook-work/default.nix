# Work MacBook configuration
{ pkgs, username, ... }:

{
  imports = [
    (import ../macbook/base.nix {
      inherit pkgs username;
      extraBrewCasks = [ ];
      extraBrews = [
        "opencode"
        "dagger"
      ];
    })
  ];

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      imports = [ ../../home/generic.nix ];
      _module.args.username = username;
      _module.args.darwinTarget = "macbook-work";

      home.packages = with pkgs; [
        uv
        aws-sam-cli
        awscli2
      ];

      # Work-specific shell config
      home.file.".config/shell/work.sh" = {
        executable = true;
        text = ''
          export NODE_EXTRA_CA_CERTS=$HOME/certs/zscaler.pem
          export SSL_CERT_FILE=$HOME/certs/zscaler.pem
          export REQUESTS_CA_BUNDLE=$HOME/certs/zscaler.pem
          export AWS_CA_BUNDLE=$HOME/certs/zscaler.pem

          # Use system clang for cargo builds (nix gcc doesn't find macOS frameworks)
          export CC=/usr/bin/clang
          export RUSTFLAGS="-C linker=/usr/bin/clang"

          # Export GitLab token for API and npm registry access
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
}
