{ pkgs, ... }:

{
  home.file.".local/bin/rotate-gitlab-token" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      CONFIG_FILE="$HOME/.config/glab-cli/config.yml"
      LOG_TAG="gitlab-token-rotation"

      log() {
          logger -t "$LOG_TAG" "$1"
          echo "[$(date -Iseconds)] $1"
      }

      # Get current token from glab config
      CURRENT_TOKEN=$(grep -A20 "hosts:" "$CONFIG_FILE" | grep "token:" | head -1 | sed 's/.*token: //' | sed 's/!!null //')

      if [[ -z "$CURRENT_TOKEN" || "$CURRENT_TOKEN" == "null" ]]; then
          log "ERROR: No token found in glab config"
          exit 1
      fi

      # Calculate new expiry (4 weeks from now)
      NEW_EXPIRY=$(date -d "+28 days" +%Y-%m-%d)

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
  };

  systemd.user.services.gitlab-token-rotate = {
    Unit = {
      Description = "Rotate GitLab personal access token";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/rotate-gitlab-token";
    };
  };

  systemd.user.timers.gitlab-token-rotate = {
    Unit = {
      Description = "Weekly GitLab token rotation";
    };
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
