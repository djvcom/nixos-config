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
        ];
      };
    };
}
