# Shared nix-darwin configuration for macOS machines
{ pkgs, username, extraBrewCasks ? [], ... }:

{
  # Required for homebrew and other user-specific options
  system.primaryUser = username;

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        username
      ];
    };
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

  nixpkgs.config.allowUnfree = true;

  # System packages available to all users
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    librewolf
    aerospace
  ];

  # Use Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Allow darwin-rebuild without password
  environment.etc."sudoers.d/darwin-rebuild".text = ''
    ${username} ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
  '';

  programs.zsh.enable = true;
  programs.bash.enable = true;

  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];

  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.bashInteractive;
  };

  # Homebrew - for packages not available in nixpkgs on macOS
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    casks = [ "ghostty" ] ++ extraBrewCasks;
  };

  system.stateVersion = 6;
}
