_:

{
  flake.modules.homeManager.wallpaper =
    { lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv) isLinux;

      set-wallpaper = pkgs.writeShellScriptBin "set-wallpaper" ''
        WALLPAPER="$1"
        if [ -z "$WALLPAPER" ]; then
          echo "Usage: set-wallpaper <path>" >&2
          exit 1
        fi

        if [ ! -e "$WALLPAPER" ]; then
          echo "File not found: $WALLPAPER" >&2
          exit 1
        fi

        for i in $(seq 1 5); do
          ${pkgs.awww}/bin/awww query && break
          ${pkgs.coreutils}/bin/sleep 0.5
          if [ "$i" -eq 5 ]; then
            echo "awww-daemon not responding after 5 attempts" >&2
            exit 1
          fi
        done

        REAL_PATH="$(${pkgs.coreutils}/bin/realpath "$WALLPAPER")"

        ${pkgs.awww}/bin/awww img "$REAL_PATH" \
          --transition-type grow \
          --transition-pos center \
          --transition-duration 1 \
          --transition-fps 60

        ${pkgs.coreutils}/bin/ln -sf "$REAL_PATH" "$HOME/.wallpapers/current"

        # matugen integration point:
        # matugen image "$REAL_PATH"
      '';

      pick-wallpaper = pkgs.writeShellScriptBin "pick-wallpaper" ''
        WALLPAPER_DIR="$HOME/.wallpapers"

        if [ ! -d "$WALLPAPER_DIR" ]; then
          ${pkgs.libnotify}/bin/notify-send -u critical "Wallpaper" "~/.wallpapers/ directory not found"
          exit 1
        fi

        SELECTION=$(${pkgs.findutils}/bin/find "$WALLPAPER_DIR" -maxdepth 1 \
          -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
          -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) \
          -exec ${pkgs.coreutils}/bin/basename {} \; \
          | ${pkgs.coreutils}/bin/sort \
          | ${pkgs.rofi}/bin/rofi -dmenu -p "Wallpaper")

        [ -z "$SELECTION" ] && exit 0

        ${set-wallpaper}/bin/set-wallpaper "$WALLPAPER_DIR/$SELECTION"
      '';
    in
    lib.mkIf isLinux {
      wayland.windowManager.hyprland.settings = {
        exec-once = [ "set-wallpaper $HOME/.wallpapers/current" ];
        bind = [ "SUPER, W, exec, pick-wallpaper" ];
      };

      home.packages = [
        pkgs.awww
        pkgs.libnotify
        set-wallpaper
        pick-wallpaper
      ];
    };
}
