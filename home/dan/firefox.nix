{ pkgs, lib, inputs, config, ... }:

let
  addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
  inherit (pkgs.stdenv) isDarwin;
in
{
  # LibreWolf on macOS uses a different profile path than Firefox
  # This activation script links extensions from the home-manager managed
  # Firefox profile to LibreWolf's actual profile location
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
        # Enable userChrome.css customisation
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Hide horizontal tab bar (using vertical tabs via Sidebery)
        "browser.tabs.tabmanager.enabled" = false;

        # Clean UI
        "browser.uidensity" = 1;
        "browser.compactmode.show" = true;

        # New tab behaviour
        "browser.startup.homepage" = "about:home";
        "browser.newtabpage.enabled" = true;

        # Smoother scrolling
        "general.smoothScroll" = true;
        "general.smoothScroll.msdPhysics.enabled" = true;
      };

      # Custom CSS for cleaner look (hide tab bar when using Sidebery)
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
}
