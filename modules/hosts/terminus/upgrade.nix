# Auto-upgrade with preflight checks and failure notifications
_:

{
  flake.modules.nixos.terminus =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      system.autoUpgrade = {
        enable = true;
        allowReboot = true;
        dates = "04:00";
        flake = "github:djvcom/nixos-config#terminus";
        flags = [
          "-L"
        ];
        rebootWindow = {
          lower = "04:00";
          upper = "05:00";
        };
        randomizedDelaySec = "5min";
      };

      systemd = {
        services = {
          nixos-upgrade = lib.mkIf config.modules.observability.enable {
            serviceConfig = {
              OnFailure = [ "nixos-upgrade-notify-failure.service" ];
            };
          };

          nixos-upgrade-notify-failure = lib.mkIf config.modules.observability.enable {
            description = "Notify on NixOS upgrade failure";
            serviceConfig.Type = "oneshot";
            path = [
              pkgs.curl
              pkgs.jq
            ];
            script = ''
              LOGS=$(journalctl -u nixos-upgrade.service -n 100 --no-pager | tail -50)
              ESCAPED_LOGS=$(echo "$LOGS" | jq -Rs .)

              # Send error log to OTEL collector
              curl -sf -X POST http://127.0.0.1:4318/v1/logs \
                -H "Content-Type: application/json" \
                -d "{
                  \"resourceLogs\": [{
                    \"resource\": {
                      \"attributes\": [
                        {\"key\": \"service.name\", \"value\": {\"stringValue\": \"nixos-upgrade\"}},
                        {\"key\": \"host.name\", \"value\": {\"stringValue\": \"terminus\"}}
                      ]
                    },
                    \"scopeLogs\": [{
                      \"logRecords\": [{
                        \"severityNumber\": 17,
                        \"severityText\": \"ERROR\",
                        \"body\": {\"stringValue\": \"NixOS auto-upgrade failed on terminus\"},
                        \"attributes\": [
                          {\"key\": \"upgrade.status\", \"value\": {\"stringValue\": \"failed\"}},
                          {\"key\": \"upgrade.logs\", \"value\": {\"stringValue\": $ESCAPED_LOGS}}
                        ]
                      }]
                    }]
                  }]
                }" || echo "Failed to send notification to OTEL"
            '';
          };

          # Pre-flight check - runs 30 min before upgrade to catch issues early
          nixos-upgrade-preflight = {
            description = "Pre-flight check for NixOS upgrade";
            unitConfig = lib.optionalAttrs config.modules.observability.enable {
              OnFailure = [ "nixos-upgrade-notify-failure.service" ];
            };
            serviceConfig.Type = "oneshot";
            path = [
              pkgs.nix
              pkgs.git
              pkgs.gnugrep
            ];
            script = ''
              set -euo pipefail
              echo "Starting NixOS upgrade pre-flight check..."

              # Force evaluation to catch warnings (eval always runs, unlike cached builds)
              echo "Evaluating flake..."
              nix eval github:djvcom/nixos-config#nixosConfigurations.terminus.config.system.build.toplevel.drvPath \
                --refresh \
                2>&1 | tee /var/tmp/nixos-preflight.log

              echo "Building configuration..."
              nix build github:djvcom/nixos-config#nixosConfigurations.terminus.config.system.build.toplevel \
                --no-link \
                -L 2>&1 | tee -a /var/tmp/nixos-preflight.log

              # Check for errors and echo them (so they appear in journal)
              if grep -qi "\berror\b\|\bfailed\b\|\bfailure\b" /var/tmp/nixos-preflight.log; then
                echo "Errors detected in build output:"
                grep -iE "\berror\b|\bfailed\b|\bfailure\b" /var/tmp/nixos-preflight.log | while read -r line; do
                  echo "BUILD ERROR: $line"
                done
              fi

              # Check for deprecation warnings and echo them (so they appear in journal)
              if grep -qi "warning\|deprecated" /var/tmp/nixos-preflight.log; then
                echo "Warnings detected in build output:"
                grep -i "warning\|deprecated" /var/tmp/nixos-preflight.log | while read -r line; do
                  echo "BUILD WARNING: $line"
                done
              fi

              echo "Pre-flight check completed successfully"
            '';
          };
        };

        timers.nixos-upgrade-preflight = {
          description = "Timer for NixOS upgrade pre-flight check";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "03:30";
            Persistent = true;
            RandomizedDelaySec = 60;
          };
        };
      };
    };
}
