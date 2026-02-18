_:

{
  flake.modules.homeManager.ghostty =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv) isDarwin;
    in
    {
      programs.ghostty = {
        enable = true;
        package = if isDarwin then null else pkgs.ghostty;
        enableZshIntegration = true;
        enableBashIntegration = true;
        settings = {
          font-family = "JetBrains Mono";
          font-size = 14;
          theme = "Catppuccin Mocha";
          window-padding-x = 10;
          window-padding-y = 10;
          window-decoration = lib.mkIf isDarwin "auto";
          macos-option-as-alt = true;
          copy-on-select = "clipboard";
          cursor-style = "block";
          cursor-style-blink = false;
          mouse-hide-while-typing = true;
          background-opacity = 0.9;
          clipboard-read = "allow";
          clipboard-write = "allow";
          keybind = "shift+enter=text:\\n";
        };
      };

      home.packages = with pkgs; [
        jetbrains-mono
      ];
    };
}
