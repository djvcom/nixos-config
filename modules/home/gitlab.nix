# GitLab token rotation - platform-aware (systemd on Linux, launchd on macOS)
_:

{
  flake.modules.homeManager.gitlab =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv) isDarwin isLinux;

      rotateScript = ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Find glab config - location varies by platform and version
        CONFIG_FILE=""
        if [[ -f "$HOME/.config/glab-cli/config.yml" ]]; then
          CONFIG_FILE="$HOME/.config/glab-cli/config.yml"
        elif [[ -f "$HOME/Library/Application Support/glab-cli/config.yml" ]]; then
          CONFIG_FILE="$HOME/Library/Application Support/glab-cli/config.yml"
        elif [[ -f "$HOME/Library/Application Support/glab-cli/config.yaml" ]]; then
          CONFIG_FILE="$HOME/Library/Application Support/glab-cli/config.yaml"
        fi

        if [[ -z "$CONFIG_FILE" ]]; then
          echo "ERROR: No glab config found"
          exit 1
        fi
        LOG_TAG="gitlab-token-rotation"

        log() {
            logger -t "$LOG_TAG" "$1"
            echo "[$(${pkgs.coreutils}/bin/date -Iseconds)] $1"
        }

        # Get current token from glab config
        CURRENT_TOKEN=$(grep -A20 "hosts:" "$CONFIG_FILE" | grep "token:" | head -1 | sed 's/.*token: //' | sed 's/!!null //')

        if [[ -z "$CURRENT_TOKEN" || "$CURRENT_TOKEN" == "null" ]]; then
            log "ERROR: No token found in glab config"
            exit 1
        fi

        # Calculate new expiry (4 weeks from now) - using GNU date from coreutils
        NEW_EXPIRY=$(${pkgs.coreutils}/bin/date -d "+28 days" +%Y-%m-%d)

        log "Rotating GitLab token, new expiry: $NEW_EXPIRY"

        # Call GitLab API to rotate token
        RESPONSE=$(${pkgs.curl}/bin/curl -sf -X POST \
            -H "PRIVATE-TOKEN: $CURRENT_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"expires_at\": \"$NEW_EXPIRY\"}" \
            "https://gitlab.com/api/v4/personal_access_tokens/self/rotate")

        if [[ $? -ne 0 ]]; then
            log "ERROR: Failed to rotate token"
            exit 1
        fi

        # Extract new token from response
        NEW_TOKEN=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.token')

        if [[ -z "$NEW_TOKEN" || "$NEW_TOKEN" == "null" ]]; then
            log "ERROR: No token in rotation response"
            exit 1
        fi

        # Update glab config with new token
        ${pkgs.gnused}/bin/sed -i "s|token: .*|token: $NEW_TOKEN|" "$CONFIG_FILE"

        log "Token rotated successfully, expires: $NEW_EXPIRY"

        # Verify new token works
        if ${pkgs.glab}/bin/glab auth status &>/dev/null; then
            log "New token verified successfully"
        else
            log "WARNING: New token verification failed"
            exit 1
        fi
      '';
    in
    {
      home.file.".local/bin/rotate-gitlab-token" = {
        executable = true;
        text = rotateScript;
      };

      systemd.user.services.gitlab-token-rotate = lib.mkIf isLinux {
        Unit = {
          Description = "Rotate GitLab personal access token";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "%h/.local/bin/rotate-gitlab-token";
        };
      };

      systemd.user.timers.gitlab-token-rotate = lib.mkIf isLinux {
        Unit = {
          Description = "Weekly GitLab token rotation";
        };
        Timer = {
          OnCalendar = "Mon 09:00";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };

      launchd.agents.gitlab-token-rotate = lib.mkIf isDarwin {
        enable = true;
        config = {
          Label = "com.user.gitlab-token-rotate";
          ProgramArguments = [
            "/bin/bash"
            "-c"
            "$HOME/.local/bin/rotate-gitlab-token"
          ];
          StartCalendarInterval = [
            {
              Weekday = 1;
              Hour = 9;
              Minute = 0;
            }
          ];
          StandardOutPath = "/tmp/gitlab-token-rotate.log";
          StandardErrorPath = "/tmp/gitlab-token-rotate.err";
        };
      };
    };
}
