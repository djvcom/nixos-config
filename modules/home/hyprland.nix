# Hyprland window manager + hyprlock (home-manager config)
_:

{
  flake.modules.homeManager.hyprland =
    { lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv) isLinux;
    in
    lib.mkIf isLinux {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        settings = {
          monitor = [ ",preferred,auto,1" ];

          env = [
            "XCURSOR_SIZE,24"
            "HYPRCURSOR_SIZE,24"
          ];

          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            "col.active_border" = "rgba(89b4faee) rgba(cba6f7ee) 45deg";
            "col.inactive_border" = "rgba(313244aa)";
            layout = "dwindle";
            allow_tearing = true;
          };

          decoration = {
            rounding = 8;
            blur = {
              enabled = true;
              size = 5;
              passes = 3;
              new_optimizations = true;
              xray = false;
            };
            shadow = {
              enabled = true;
              range = 15;
              render_power = 3;
              color = "rgba(1a1a2eee)";
            };
          };

          animations = {
            enabled = true;
            bezier = [
              "ease, 0.25, 0.1, 0.25, 1"
              "overshot, 0.05, 0.9, 0.1, 1.05"
            ];
            animation = [
              "windows, 1, 4, overshot, slide"
              "windowsOut, 1, 4, ease, slide"
              "border, 1, 10, ease"
              "fade, 1, 4, ease"
              "workspaces, 1, 4, overshot, slidevert"
            ];
          };

          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };

          input = {
            kb_layout = "us";
            follow_mouse = 1;
            sensitivity = 0;
            accel_profile = "flat";
          };

          misc = {
            force_default_wallpaper = 0;
            vfr = true;
            vrr = 1;
          };

          windowrule = [
            "immediate on, match:class ^(steam_app_.*)$"
            "immediate on, match:class ^(gamescope)$"
            "float on, match:class ^(pavucontrol)$"
            "float on, match:class ^(blueman-manager)$"
            "float on, match:class ^(.blueman-manager-wrapped)$"
            "float on, match:title ^(Steam - News)$"
            "float on, match:title ^(Friends List)$"
            "workspace 5, match:class ^(steam)$"
            "workspace 5, match:title ^(Steam)$"
          ];

          "$mod" = "SUPER";

          bind = [
            "$mod, Return, exec, ghostty"
            "$mod, D, exec, wofi --show drun"
            "$mod, Q, killactive,"
            "$mod, M, exit,"
            "$mod, V, togglefloating,"
            "$mod, F, fullscreen, 0"
            "$mod, P, pseudo,"

            "$mod, H, movefocus, l"
            "$mod, J, movefocus, d"
            "$mod, K, movefocus, u"
            "$mod, L, movefocus, r"

            "$mod SHIFT, H, movewindow, l"
            "$mod SHIFT, J, movewindow, d"
            "$mod SHIFT, K, movewindow, u"
            "$mod SHIFT, L, movewindow, r"

            "$mod ALT, H, resizeactive, -50 0"
            "$mod ALT, L, resizeactive, 50 0"
            "$mod ALT, K, resizeactive, 0 -50"
            "$mod ALT, J, resizeactive, 0 50"

            "$mod, 1, workspace, 1"
            "$mod, 2, workspace, 2"
            "$mod, 3, workspace, 3"
            "$mod, 4, workspace, 4"
            "$mod, 5, workspace, 5"
            "$mod, 6, workspace, 6"
            "$mod, 7, workspace, 7"
            "$mod, 8, workspace, 8"
            "$mod, 9, workspace, 9"

            "$mod SHIFT, 1, movetoworkspace, 1"
            "$mod SHIFT, 2, movetoworkspace, 2"
            "$mod SHIFT, 3, movetoworkspace, 3"
            "$mod SHIFT, 4, movetoworkspace, 4"
            "$mod SHIFT, 5, movetoworkspace, 5"
            "$mod SHIFT, 6, movetoworkspace, 6"
            "$mod SHIFT, 7, movetoworkspace, 7"
            "$mod SHIFT, 8, movetoworkspace, 8"
            "$mod SHIFT, 9, movetoworkspace, 9"

            '', Print, exec, grim -g "$(slurp)" - | wl-copy''
            "SHIFT, Print, exec, grim - | wl-copy"

            "$mod SHIFT, Escape, exec, hyprlock"
          ];

          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];

          exec-once = [
            "waybar"
            "dunst"
            "swww-daemon"
            "nm-applet --indicator"
            "wl-paste --type text --watch cliphist store"
            "wl-paste --type image --watch cliphist store"
          ];
        };
      };

      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            grace = 5;
            hide_cursor = true;
          };
          background = [
            {
              monitor = "";
              blur_passes = 3;
              blur_size = 8;
            }
          ];
          input-field = [
            {
              monitor = "";
              size = "200, 50";
              outline_thickness = 3;
              dots_size = 0.33;
              dots_spacing = 0.15;
              dots_center = false;
              outer_color = "rgb(89b4fa)";
              inner_color = "rgb(1e1e2e)";
              font_color = "rgb(cdd6f4)";
              fade_on_empty = true;
              placeholder_text = "<i>Password...</i>";
              hide_input = false;
              rounding = 8;
              position = "0, -20";
              halign = "center";
              valign = "center";
            }
          ];
        };
      };

      home.packages = with pkgs; [
        waybar
        wofi
        dunst
        swww
        grim
        slurp
        hyprpicker
        wlogout
      ];
    };
}
