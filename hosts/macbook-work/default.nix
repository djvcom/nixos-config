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
      ];

      # Work-specific shell config for GitLab token
      home.file.".config/shell/work.sh" = {
        executable = true;
        text = ''
          # Export GitLab token for API and npm registry access
          # macOS uses ~/Library/Application Support, Linux uses ~/.config
          _glab_config="$HOME/Library/Application Support/glab-cli/config.yaml"
          if [ -f "$_glab_config" ]; then
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
