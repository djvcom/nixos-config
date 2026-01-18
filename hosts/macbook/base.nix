# Shared nix-darwin configuration for macOS machines
{
  pkgs,
  username,
  extraBrewCasks ? [ ],
  ...
}:

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

    shells = with pkgs; [
      bashInteractive
      zsh
    ];

    # SSL certificates for nix-installed tools
    variables = {
      NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    };
  };

  # Use Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  programs.zsh.enable = true;
  programs.bash.enable = true;

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
    casks = [
      "ghostty"
      "google-chrome"
    ]
    ++ extraBrewCasks;
  };

  system.stateVersion = 6;
}
