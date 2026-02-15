# Firefox/LibreWolf with extensions
{ inputs, ... }:

{
  flake.modules.homeManager.firefox =
    {
      pkgs,
      lib,
      ...
    }:
    let
      addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
      inherit (pkgs.stdenv) isDarwin;
    in
    {
      home.activation.linkLibreWolfExtensions = lib.mkIf isDarwin (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          LIBREWOLF_PROFILES="$HOME/Library/Application Support/librewolf/Profiles"
          FIREFOX_EXTENSIONS="$HOME/Library/Application Support/Firefox/Profiles/default/extensions"

          if [ -d "$LIBREWOLF_PROFILES" ] && [ -d "$FIREFOX_EXTENSIONS" ]; then
            for profile in "$LIBREWOLF_PROFILES"/*; do
              if [ -d "$profile" ]; then
                mkdir -p "$profile/extensions"
                for ext in "$FIREFOX_EXTENSIONS"/*; do
                  if [ -e "$ext" ]; then
                    extname=$(basename "$ext")
                    ln -sf "$ext" "$profile/extensions/$extname"
                  fi
                done
              fi
            done
          fi
        ''
      );

      programs.firefox = {
        enable = true;
        package = pkgs.librewolf;
        profiles.default = {
          isDefault = true;
          extensions.packages = with addons; [
            sidebery
            darkreader
            bitwarden
          ];
          settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.tabs.tabmanager.enabled" = false;
            "browser.uidensity" = 1;
            "browser.compactmode.show" = true;
            "browser.startup.homepage" = "about:home";
            "browser.newtabpage.enabled" = true;
            "general.smoothScroll" = true;
            "general.smoothScroll.msdPhysics.enabled" = true;
          };
          userChrome = ''
            /* Hide horizontal tab bar - using Sidebery vertical tabs */
            #TabsToolbar {
              visibility: collapse !important;
            }

            /* Cleaner toolbar */
            #nav-bar {
              border: none !important;
              box-shadow: none !important;
            }

            /* Minimal window controls spacing on macOS */
            .titlebar-buttonbox-container {
              margin-left: 8px !important;
            }
          '';
        };
      };
    };
}
