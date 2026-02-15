{ lib, pkgs, ... }:

let
  inherit (pkgs.stdenv) isLinux;
in
lib.mkIf isLinux {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "gamemode"
          "pulseaudio"
          "bluetooth"
          "network"
          "cpu"
          "memory"
          "temperature"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
          };
          on-click = "activate";
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%A, %d %B %Y}";
          tooltip-format = "<tt>{calendar}</tt>";
        };

        cpu = {
          format = " {usage}%";
          interval = 5;
        };

        memory = {
          format = " {percentage}%";
          interval = 5;
        };

        temperature = {
          format = " {temperatureC}C";
          critical-threshold = 80;
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = " muted";
          format-icons.default = [
            ""
            ""
            ""
          ];
          on-click = "pavucontrol";
        };

        network = {
          format-wifi = " {signalStrength}%";
          format-ethernet = " {ipaddr}";
          format-disconnected = " disconnected";
          tooltip-format = "{ifname}: {ipaddr}";
        };

        bluetooth = {
          format = " {status}";
          format-connected = " {device_alias}";
          on-click = "blueman-manager";
        };

        gamemode = {
          format = "{glyph}";
          glyph = "";
          format-alt = "{glyph} {count}";
          tooltip = true;
          tooltip-format = "GameMode active: {count} games";
          hide-not-running = true;
        };

        tray = {
          spacing = 10;
        };
      };
    };
    style = ''
      * {
        font-family: "JetBrains Mono", "Font Awesome 6 Free";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: rgba(30, 30, 46, 0.9);
        color: #cdd6f4;
        border-bottom: 2px solid rgba(137, 180, 250, 0.3);
      }

      #workspaces button {
        padding: 0 8px;
        color: #6c7086;
        border-bottom: 2px solid transparent;
      }

      #workspaces button.active {
        color: #89b4fa;
        border-bottom: 2px solid #89b4fa;
      }

      #clock, #cpu, #memory, #temperature, #pulseaudio,
      #network, #bluetooth, #gamemode, #tray {
        padding: 0 10px;
      }

      #gamemode {
        color: #f9e2af;
      }

      #temperature.critical {
        color: #f38ba8;
      }
    '';
  };
}
