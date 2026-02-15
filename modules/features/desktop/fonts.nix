# Font configuration
_:

{
  flake.modules.nixos.fonts =
    { pkgs, ... }:
    {
      fonts = {
        packages = with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
          jetbrains-mono
          font-awesome
          nerd-fonts.jetbrains-mono
        ];
        fontconfig.defaultFonts = {
          monospace = [ "JetBrains Mono" ];
          sansSerif = [ "Noto Sans" ];
          serif = [ "Noto Serif" ];
        };
      };
    };
}
