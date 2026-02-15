# Gaming: Steam, Gamescope, Gamemode
_:

{
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      nixpkgs.config.allowUnfree = true;

      programs = {
        steam = {
          enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = false;
          gamescopeSession.enable = true;
          extraCompatPackages = with pkgs; [
            proton-ge-bin
          ];
        };

        gamescope = {
          enable = true;
          capSysNice = true;
        };

        gamemode = {
          enable = true;
          settings = {
            general.renice = 10;
            gpu = {
              apply_gpu_optimisations = "accept-responsibility";
              gpu_device = 0;
            };
          };
        };
      };

      environment.systemPackages = with pkgs; [
        lutris
        heroic
        mangohud
        protonup-qt
        wine
        winetricks
      ];
    };
}
