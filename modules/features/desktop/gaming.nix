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
        xenia-canary
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav
      ];
    };
}
