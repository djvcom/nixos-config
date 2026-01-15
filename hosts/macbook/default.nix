# Shared nix-darwin configuration for macOS machines
# Username is read from $USER environment variable at build time
{ pkgs, username, ... }:

{
  # Required for homebrew and other user-specific options
  system.primaryUser = username;
  # Nix configuration
  nix = {
    # Disable legacy channels (using flakes instead)
    channel.enable = false;
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

  environment = {
    # System packages available to all users
    systemPackages = with pkgs; [
      vim
      git
      curl
      librewolf
      aerospace
    ];

    # Allow darwin-rebuild without password
    etc."sudoers.d/darwin-rebuild".text = ''
      ${username} ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
    '';

    # Shells available to users
    shells = with pkgs; [
      bashInteractive
      zsh
    ];
  };

  # Use Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Create /etc/zshrc that loads nix-darwin environment
  programs.zsh.enable = true;
  programs.bash.enable = true;

  # Define the user (required for home-manager to derive home directory)
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.bashInteractive;
  };

  # Home-manager configuration for the current user
  home-manager.users.${username} =
    { ... }:
    {
      imports = [ ../../home/generic.nix ];
      # Pass username to the generic config
      _module.args.username = username;
    };

  # Homebrew - for packages not available in nixpkgs on macOS
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    casks = [
      "ghostty"
      "gog-galaxy"
      "google-chrome"
    ];
  };

  # Used for backwards compatibility
  system.stateVersion = 6;
}
