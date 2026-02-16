# Oshun desktop - feature selection and host-specific config
{ inputs, ... }:

{
  flake.modules.nixos.oshun =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        # Tools
        disko
        agenix
        home-manager

        # Base
        boot
        security
        ssh
        nix-settings
        base-packages

        # Desktop
        hyprland
        pipewire
        bluetooth
        nvidia
        gaming
        fonts
        desktop-packages
      ];

      services.hardware.openrgb.enable = true;

      powerManagement = {
        powerDownCommands = ''
          ${pkgs.openrgb}/bin/openrgb --device 0 --mode direct --color 0D0D0D --device 1 --mode direct --color 0D0D0D
        '';
        resumeCommands = ''
          ${pkgs.openrgb}/bin/openrgb --device 0 --mode direct --color FFFFFF --device 1 --mode direct --color FFFFFF
        '';
      };

      networking = {
        hostName = "oshun";
        networkmanager.enable = true;
        firewall.enable = true;
      };

      nixpkgs.config.allowUnfree = true;

      users.users.dan = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "audio"
          "input"
          "gamemode"
        ];
        shell = pkgs.bashInteractive;
      };

      nix.optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };

      system = {
        autoUpgrade = {
          enable = true;
          allowReboot = true;
          dates = "07:00";
          flake = "github:djvcom/nixos-config#oshun";
          flags = [ "-L" ];
          rebootWindow = {
            lower = "07:00";
            upper = "08:00";
          };
          randomizedDelaySec = "5min";
        };

        stateVersion = "25.11";
      };

      home-manager.users.dan =
        { ... }:
        {
          imports = with inputs.self.modules.homeManager; [
            base
            shell
            git
            neovim
            firefox
            ghostty
            hyprland
            waybar
            gitlab
            cursor
          ];
          home.username = "dan";
          home.homeDirectory = "/home/dan";
        };
    };
}
