_:

{
  flake.modules.darwin.base =
    { pkgs, username, ... }:
    {
      # Required for homebrew and other user-specific options
      system.primaryUser = username;

      nix = {
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
        systemPackages = with pkgs; [
          vim
          git
          curl
          librewolf
          aerospace
        ];

        etc."sudoers.d/darwin-rebuild".text = ''
          ${username} ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
        '';

        shells = with pkgs; [
          bashInteractive
          zsh
        ];

        variables = {
          NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
      };

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
        ];
      };

      system.stateVersion = 6;
    };
}
