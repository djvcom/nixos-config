{ inputs, ... }:

{
  flake.modules.nixos.base-packages =
    { pkgs, ... }:
    {
      environment.pathsToLink = [
        "/share/applications"
        "/share/xdg-desktop-portal"
      ];

      environment.systemPackages =
        with pkgs;
        [
          git
          vim
          curl
          wget
          age
          gnumake
          just
          nh
          ghostty.terminfo
          fastfetch
        ]
        ++ [
          inputs.dagger.packages.${pkgs.stdenv.hostPlatform.system}.dagger
        ];

      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          stdenv.cc.cc.lib
          glib
          nss
          nspr
          dbus
          atk
          at-spi2-atk
          libdrm
          xorg.libX11
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXrandr
          xorg.libxcb
          mesa
          libgbm
          expat
          libxkbcommon
          pango
          cairo
          alsa-lib
          at-spi2-core
        ];
      };
    };
}
