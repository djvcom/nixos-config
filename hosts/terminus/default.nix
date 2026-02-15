{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ../../modules/base.nix
    ../../modules/observability.nix
    ../../modules/backup.nix

    # Host-specific configuration
    ./host-secrets.nix
    ./hardening.nix
    ./traefik.nix

    # Services
    ./services/djv.nix
    ./services/kanidm.nix
    ./services/vaultwarden.nix
    ./services/openbao.nix
    ./services/stalwart.nix
    ./services/garage.nix
    ./services/valkey.nix
    ./services/datadog.nix
    ./services/roundcube.nix
    ./services/dashboard.nix
    ./services/sidereal.nix
  ];

  networking = {
    hostName = "terminus";
    useDHCP = false;
    # Resolve mail.djv.sh to localhost for Roundcube IMAP connection
    hosts."127.0.0.1" = [ "mail.djv.sh" ];
    interfaces.eth0 = {
      ipv4.addresses = [
        {
          address = "88.99.1.188";
          prefixLength = 24;
        }
      ];
      ipv6.addresses = [
        {
          address = "2a01:4f8:173:28ab::2";
          prefixLength = 64;
        }
      ];
    };
    nameservers = [
      "185.12.64.1"
      "185.12.64.2"
    ];
    defaultGateway = "88.99.1.129";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        443
      ];
      allowPing = true;
      logRefusedConnections = true;
      # Allow OTEL ports only from Docker network
      extraCommands = ''
        iptables -I nixos-fw 5 -p tcp -s 172.17.0.0/16 --dport 4317 -j nixos-fw-accept
        iptables -I nixos-fw 5 -p tcp -s 172.17.0.0/16 --dport 4318 -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -D nixos-fw -p tcp -s 172.17.0.0/16 --dport 4317 -j nixos-fw-accept 2>/dev/null || true
        iptables -D nixos-fw -p tcp -s 172.17.0.0/16 --dport 4318 -j nixos-fw-accept 2>/dev/null || true
      '';
    };
  };

  # Observability pipeline to Datadog
  modules.observability = {
    enable = true;
    tokenSecretPath = config.age.secrets.datadog-api-key.path;
    # Set explicit hostname to prevent host.id from creating duplicate hosts
    hostname = "terminus";
    exporters = {
      datadog = {
        api.key = "\${env:DD_API_KEY}";
      };
    };
    extensions = {
      datadog = {
        api.key = "\${env:DD_API_KEY}";
      };
    };
    pipelines = {
      metrics = {
        receivers = [
          "otlp"
          "hostmetrics"
        ];
        processors = [
          "resourcedetection"
          "transform/hostname"
          "batch"
        ];
        exporters = [ "datadog" ];
      };
      traces = {
        receivers = [ "otlp" ];
        processors = [
          "resourcedetection"
          "transform/hostname"
          "batch"
        ];
        exporters = [ "datadog" ];
      };
      logs = {
        receivers = [ "otlp" ];
        processors = [
          "resourcedetection"
          "transform/hostname"
          "batch"
        ];
        exporters = [ "datadog" ];
      };
      "logs/system" = {
        receivers = [ "journald" ];
        processors = [
          "transform/logs"
          "resourcedetection"
          "transform/hostname"
          "batch"
        ];
        exporters = [ "datadog" ];
      };
    };
  };

  # Automated backups to Garage (local S3)
  modules.backup = {
    enable = true;
    repository = "s3:http://127.0.0.1:3900/backups";
    environmentFile = config.age.secrets.backup-credentials.path;

    paths = [
      "/var/lib/kanidm"
      "/var/backup/kanidm"
      "/var/lib/stalwart-mail/data"
      "/var/lib/openbao"
    ];

    postgresqlDatabases = [
      "djv"
      "vaultwarden"
      "roundcube"
    ];

    schedule = "daily";
    retention = {
      daily = 7;
      weekly = 4;
      monthly = 6;
    };
  };

  # User and group configuration
  users = {
    # Shared group for services needing mail credentials
    groups.mail-secrets = { };

    users = {
      # Primary user
      dan = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "kvm"
          "libvirtd"
          "docker"
        ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKGGvADTZrv8lir6I2mTEtef/r1StZ0pfAkRNZcr9tE dan@macbook-personal"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3DO7MvH49txkJjxZDZb4S3IWdeuEvN3UzPGbkvEtbE dan@macbook-work"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbuNAs2R2clu+9Xd37pWsQblShESDYejJAGfgCxSKG/ dan@oshun"
        ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    zellij
    nftables
    nodejs_24
  ];

  virtualisation = {
    libvirtd = {
      enable = true;
      allowedBridges = [ "virbr0" ];
    };
    docker = {
      enable = true;
    };
  };

  # PostgreSQL with proper authentication (shared by multiple services)
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "djv"
      "vaultwarden"
      "roundcube"
    ];
    ensureUsers = [
      {
        name = "dan";
        ensureClauses.superuser = true;
        ensureClauses.login = true;
      }
      {
        name = "djv";
        ensureDBOwnership = true;
      }
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
      }
      # Datadog monitoring user
      {
        name = "datadog";
        ensureClauses.login = true;
      }
    ];
    settings = {
      password_encryption = "scram-sha-256";
      # Required for pg_stat_statements (Datadog DBM)
      shared_preload_libraries = "pg_stat_statements";
      "pg_stat_statements.track" = "all";
      "pg_stat_statements.max" = 10000;
      track_activity_query_size = 4096;
      track_io_timing = "on";
    };
    authentication = lib.mkForce ''
      # Local connections use peer authentication (matches OS user)
      local all all peer
      # Network connections require password (scram-sha-256)
      host all all 127.0.0.1/32 scram-sha-256
      host all all ::1/128 scram-sha-256
    '';
  };

  # ACME defaults for certificate management
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@djv.sh";
  };

  # Nix store optimisation
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # Automatic system upgrades
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

  # Upgrade monitoring and pre-flight checks
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

          # Then build to ensure it actually works
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

      # Configure PostgreSQL datadog user for Database Monitoring
      postgresql-datadog-setup = {
        description = "Configure PostgreSQL datadog user for DBM";
        after = [ "postgresql.service" ];
        requires = [ "postgresql.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        path = [
          config.services.postgresql.package
          pkgs.sudo
        ];

        script = ''
          # Set password for datadog user
          PASSWORD=$(cat ${config.age.secrets.datadog-postgres-password.path})
          sudo -u postgres psql -d postgres -c "ALTER USER datadog WITH PASSWORD '$PASSWORD';"

          # Grant pg_monitor role for monitoring access
          sudo -u postgres psql -d postgres -c "GRANT pg_monitor TO datadog;"

          # Create pg_stat_statements extension and helper functions in each database
          for db in djv vaultwarden postgres; do
            sudo -u postgres psql -d "$db" -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;" 2>/dev/null || true

            # Create datadog schema and helper functions for explain plans
            sudo -u postgres psql -d "$db" <<'EOSQL'
              CREATE SCHEMA IF NOT EXISTS datadog;
              GRANT USAGE ON SCHEMA datadog TO datadog;
              GRANT USAGE ON SCHEMA public TO datadog;

              CREATE OR REPLACE FUNCTION datadog.pg_stat_activity()
              RETURNS SETOF pg_stat_activity AS
              $$ SELECT * FROM pg_catalog.pg_stat_activity; $$
              LANGUAGE sql SECURITY DEFINER;

              CREATE OR REPLACE FUNCTION datadog.pg_stat_statements()
              RETURNS SETOF pg_stat_statements AS
              $$ SELECT * FROM pg_stat_statements; $$
              LANGUAGE sql SECURITY DEFINER;

              CREATE OR REPLACE FUNCTION datadog.explain_statement(
                 l_query TEXT,
                 OUT explain JSON
              ) RETURNS SETOF JSON AS $$
              DECLARE curs REFCURSOR; plan JSON;
              BEGIN
                 OPEN curs FOR EXECUTE pg_catalog.concat('EXPLAIN (FORMAT JSON) ', l_query);
                 FETCH curs INTO plan; CLOSE curs;
                 RETURN QUERY SELECT plan;
              END; $$ LANGUAGE 'plpgsql' SECURITY DEFINER;
          EOSQL
          done
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

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.dan =
      { ... }:
      {
        imports = [ ../../home/generic.nix ];
        _module.args.username = "dan";
      };
  };

  system.stateVersion = "25.05";
}
