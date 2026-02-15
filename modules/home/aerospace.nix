# AeroSpace tiling window manager for macOS
_:

{
  flake.modules.homeManager.aerospace =
    { lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv) isDarwin;
    in
    {
      home.file.".aerospace.toml" = lib.mkIf isDarwin {
        text = ''
          # Aerospace - i3-like tiling window manager for macOS

          # Start on login
          start-at-login = true

          # Launch apps on startup
          after-startup-command = [
            "exec-and-forget open '/Applications/Nix Apps/LibreWolf.app'",
            "workspace 2",
            "exec-and-forget open -a Ghostty"
          ]

          # Mouse follows focus
          on-focused-monitor-changed = ["move-mouse monitor-lazy-center"]

          # Default to horizontal tiling (side by side)
          default-root-container-layout = "tiles"
          default-root-container-orientation = "horizontal"

          # Gaps
          [gaps]
          inner.horizontal = 10
          inner.vertical = 10
          outer.left = 10
          outer.bottom = 10
          outer.top = 10
          outer.right = 10

          # Main mode bindings
          [mode.main.binding]
          # Focus windows
          ctrl-alt-h = "focus left"
          ctrl-alt-j = "focus down"
          ctrl-alt-k = "focus up"
          ctrl-alt-l = "focus right"

          alt-n = "exec-and-forget aerospace move-node-to-workspace next"

          # Move windows
          ctrl-alt-shift-h = "move left"
          ctrl-alt-shift-j = "move down"
          ctrl-alt-shift-k = "move up"
          ctrl-alt-shift-l = "move right"

          # Resize windows
          ctrl-alt-minus = "resize smart -50"
          ctrl-alt-equal = "resize smart +50"

          # Layouts
          ctrl-alt-slash = "layout tiles horizontal vertical"
          ctrl-alt-comma = "layout accordion horizontal vertical"
          ctrl-alt-f = "fullscreen"

          # Workspaces
          ctrl-alt-1 = "workspace 1"
          ctrl-alt-2 = "workspace 2"
          ctrl-alt-3 = "workspace 3"
          ctrl-alt-4 = "workspace 4"
          ctrl-alt-5 = "workspace 5"
          ctrl-alt-6 = "workspace 6"
          ctrl-alt-7 = "workspace 7"
          ctrl-alt-8 = "workspace 8"
          ctrl-alt-9 = "workspace 9"

          # Move window to workspace
          ctrl-alt-shift-1 = "move-node-to-workspace 1"
          ctrl-alt-shift-2 = "move-node-to-workspace 2"
          ctrl-alt-shift-3 = "move-node-to-workspace 3"
          ctrl-alt-shift-4 = "move-node-to-workspace 4"
          ctrl-alt-shift-5 = "move-node-to-workspace 5"
          ctrl-alt-shift-6 = "move-node-to-workspace 6"
          ctrl-alt-shift-7 = "move-node-to-workspace 7"
          ctrl-alt-shift-8 = "move-node-to-workspace 8"
          ctrl-alt-shift-9 = "move-node-to-workspace 9"

          # Reload config
          ctrl-alt-shift-c = "reload-config"

          # Service mode for less common commands
          ctrl-alt-shift-semicolon = "mode service"

          [mode.service.binding]
          esc = ["reload-config", "mode main"]
          r = ["flatten-workspace-tree", "mode main"]
          f = ["layout floating tiling", "mode main"]
          backspace = ["close-all-windows-but-current", "mode main"]

          # Window rules - assign apps to workspaces
          [[on-window-detected]]
          if.app-id = "org.mozilla.librewolf"
          run = ["move-node-to-workspace 1"]
        '';
      };
    };
}
