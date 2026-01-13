# Work MacBook configuration
{ pkgs, username, ... }:

{
  imports = [
    (import ../macbook/base.nix {
      inherit pkgs username;
      extraBrewCasks = [];
    })
  ];

  # Home-manager configuration for the current user
  home-manager.users.${username} =
    { ... }:
    {
      imports = [ ../../home/generic.nix ];
      _module.args.username = username;
      _module.args.isPersonal = false;

      # Work-specific packages
      home.packages = with pkgs; [
        uv
        aws-sam-cli 
      ];

      # Work-specific shell config for GitLab token
      home.file.".config/shell/work.sh" = {
        executable = true;
        text = ''
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
