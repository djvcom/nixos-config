# Shared nix-darwin configuration for macOS machines
# Username is read from $USER environment variable at build time
{ pkgs, username, ... }:

{
  # Nix configuration
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Recommended by nix-darwin
      trusted-users = [
        "root"
        username
      ];
    };
    # Automatic garbage collection
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages available to all users
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
  ];

  # Use Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Create /etc/zshrc that loads nix-darwin environment
  programs.zsh.enable = true;
  programs.bash.enable = true;

  # Shells available to users
  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];

  # Home-manager configuration for the current user
  home-manager.users.${username} =
    { ... }:
    {
      imports = [ ../../home/generic.nix ];
      # Pass username to the generic config
      _module.args.username = username;
    };

  # Used for backwards compatibility
  system.stateVersion = 6;
}
