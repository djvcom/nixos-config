_:

{
  flake.modules.homeManager.waybar =
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
            margin-top = 6;
            margin-left = 8;
            margin-right = 8;

            modules-left = [ "hyprland/workspaces" ];
            modules-center = [ "hyprland/window" ];
            modules-right = [
              "gamemode"
              "tray"
              "pulseaudio"
              "bluetooth"
              "network"
              "cpu"
              "memory"
              "temperature"
              "clock"
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

            "hyprland/window" = {
              max-length = 50;
              separate-outputs = true;
            };

            clock = {
              format = "󰥔 {:%H:%M  ·  %a %d %b}";
              format-alt = "󰥔 {:%A, %d %B %Y  ·  %H:%M:%S}";
              tooltip-format = "<tt>{calendar}</tt>";
            };

            cpu = {
              format = "󰍛 {usage}%";
              interval = 5;
            };

            memory = {
              format = "󰘚 {percentage}%";
              interval = 5;
            };

            temperature = {
              format = "󰔏 {temperatureC}°C";
              critical-threshold = 80;
            };

            pulseaudio = {
              format = "{icon} {volume}%";
              format-muted = "󰝟 muted";
              format-icons.default = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
              on-click = "pavucontrol";
            };

            network = {
              format-wifi = "󰤨 {signalStrength}%";
              format-ethernet = "󰈀 {ipaddr}";
              format-disconnected = "󰤭 disconnected";
              tooltip-format = "{ifname}: {ipaddr}";
            };

            bluetooth = {
              format = "󰂯 {status}";
              format-connected = "󰂱 {device_alias}";
              on-click = "blueman-manager";
            };

            gamemode = {
              format = "{glyph}";
              glyph = "󰊗";
              format-alt = "{glyph} {count}";
              tooltip = true;
              tooltip-format = "GameMode active: {count} games";
              hide-not-running = true;
            };

            tray = {
              spacing = 8;
            };
          };
        };
        style = ''
          * {
            font-family: "JetBrainsMono Nerd Font", "Noto Sans";
            font-size: 14px;
            min-height: 0;
          }

          window#waybar {
            background-color: rgba(17, 17, 27, 0.75);
            border-radius: 14px;
            color: #cdd6f4;
          }

          tooltip {
            background-color: #1e1e2e;
            border: 2px solid #45475a;
            border-radius: 12px;
          }

          #workspaces {
            background-color: rgba(49, 50, 68, 0.6);
            border-radius: 12px;
            padding: 0 4px;
            margin: 5px 4px;
          }

          #workspaces button {
            color: #585b70;
            padding: 0 7px;
            border-radius: 10px;
            margin: 3px 1px;
            transition: all 0.2s ease;
          }

          #workspaces button.active {
            color: #cdd6f4;
            background-color: rgba(137, 180, 250, 0.25);
          }

          #workspaces button:hover {
            color: #a6adc8;
            background-color: rgba(108, 112, 134, 0.15);
          }

          #window {
            color: #a6adc8;
            font-size: 13px;
          }

          #clock,
          #cpu,
          #memory,
          #temperature,
          #pulseaudio,
          #network,
          #bluetooth,
          #gamemode,
          #tray {
            background-color: rgba(49, 50, 68, 0.6);
            border-radius: 12px;
            padding: 0 14px;
            margin: 5px 3px;
            transition: all 0.2s ease;
          }

          #clock:hover,
          #cpu:hover,
          #memory:hover,
          #temperature:hover,
          #pulseaudio:hover,
          #network:hover,
          #bluetooth:hover {
            background-color: rgba(69, 71, 90, 0.7);
          }

          #clock {
            color: #89b4fa;
          }

          #cpu {
            color: #a6e3a1;
          }

          #memory {
            color: #f9e2af;
          }

          #temperature {
            color: #fab387;
          }

          #pulseaudio {
            color: #cba6f7;
          }

          #network {
            color: #94e2d5;
          }

          #bluetooth {
            color: #89b4fa;
          }

          #gamemode {
            color: #f9e2af;
          }

          #temperature.critical {
            color: #f38ba8;
            animation: pulse 1s ease-in-out infinite alternate;
          }

          @keyframes pulse {
            to { color: #eba0ac; }
          }
        '';
      };
    };
}
