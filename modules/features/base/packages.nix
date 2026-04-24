_:

{
  flake.modules.nixos.base-packages =
    { pkgs, ... }:
    {
      environment.pathsToLink = [
        "/share/applications"
        "/share/xdg-desktop-portal"
      ];

      environment.systemPackages = with pkgs; [
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
          libx11
          libxcomposite
          libxdamage
          libxext
          libxfixes
          libxrandr
          libxcb
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
