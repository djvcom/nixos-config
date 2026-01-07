# Datadog Agent for PostgreSQL DBM and Valkey monitoring
#
# Runs alongside OpenTelemetry Collector - provides deep database monitoring
# features not available via OTEL (query samples, explain plans, wait events).
{ config, pkgs, ... }:

let
  # Build the integrations with their Python dependencies
  # This creates a Python environment with all integration checks
  # Note: postgres needs many deps for full DBM functionality
  extraIntegrations = {
    postgres =
      ps: with ps; [
        azure-identity # Azure managed identity
        boto3 # AWS RDS integration
        mmh3 # MurmurHash3 for query fingerprinting
        pg8000
        psycopg
        psycopg-pool # Connection pooling for psycopg3
        psycopg2
        semver
      ];
    redisdb = ps: with ps; [ redis ];
  };

  # Get the integrations package which includes a Python environment
  # with all the datadog_checks modules properly installed
  integrationsEnv = pkgs.datadog-integrations-core extraIntegrations;
in
{
  services.datadog-agent = {
    enable = true;
    # API key is extracted from env var format by pre-start script
    apiKeyFile = "/run/datadog-agent/api-key";

    # Hostname shown in Datadog
    hostname = "terminus";

    # Use the integrations defined in the let block
    inherit extraIntegrations;

    # Tags applied to all metrics
    tags = [
      "env:production"
      "host:terminus"
    ];

    # Valkey/Redis check - no auth needed (localhost only)
    checks = {
      redisdb = {
        init_config = { };
        instances = [
          {
            host = "127.0.0.1";
            port = 6379;
            tags = [
              "service:valkey"
              "env:production"
            ];
          }
        ];
      };
    };

    # Extra datadog.yaml configuration
    extraConfig = {
      log_level = "INFO";
      # Database monitoring
      database_monitoring = {
        enabled = true;
      };
    };
  };

  # PostgreSQL check configuration with password from secret
  # We generate this separately because the password needs to come from agenix
  systemd.services.datadog-agent-postgres-config = {
    description = "Generate Datadog PostgreSQL check config";
    after = [ "postgresql.service" ];
    before = [ "datadog-agent.service" ];
    wantedBy = [ "datadog-agent.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };

    script = ''
      mkdir -p /etc/datadog-agent/conf.d/postgres.d
      PASSWORD=$(cat ${config.age.secrets.datadog-postgres-password.path})
      cat > /etc/datadog-agent/conf.d/postgres.d/conf.yaml <<EOF
      init_config:

      instances:
        - dbm: true
          host: 127.0.0.1
          port: 5432
          username: datadog
          password: $PASSWORD
          dbname: postgres
          tags:
            - service:postgresql
            - env:production
          # Autodiscover all databases
          database_autodiscovery:
            enabled: true
            include:
              - ".*"
          # Collect relation metrics
          relations:
            - relation_regex: ".*"
          # Query samples and metrics for DBM
          query_samples:
            enabled: true
          query_metrics:
            enabled: true
          collect_bloat_metrics: true
      EOF
      chown datadog:datadog /etc/datadog-agent/conf.d/postgres.d/conf.yaml
      chmod 600 /etc/datadog-agent/conf.d/postgres.d/conf.yaml
    '';
  };

  # Ensure datadog user can read redis socket if needed
  users.users.datadog.extraGroups = [ "redis-default" ];

  # Extract API key and fix PYTHONPATH for integrations
  # The existing secret is in DD_API_KEY=xxx format (for OTEL Collector)
  # The agent's wrapper uses --set PYTHONPATH which overwrites the environment,
  # so we create a custom wrapper that properly includes integrations
  systemd.services.datadog-agent =
    let
      # Create a patched agent wrapper that includes integrations in PYTHONPATH
      # The original wrapper only includes the agent's site-packages
      patchedAgent = pkgs.writeShellScriptBin "datadog-agent-patched" ''
        # Set PYTHONPATH to include both integrations and agent site-packages
        export PYTHONPATH="${integrationsEnv.python}/${integrationsEnv.python.sitePackages}:${pkgs.datadog-agent}/${pkgs.python313.sitePackages}"

        # Extract LD_LIBRARY_PATH from the original wrapper script
        # The wrapper sets LD_LIBRARY_PATH for rtloader and systemd libs
        eval "$(grep -E '^(export )?LD_LIBRARY_PATH' ${pkgs.datadog-agent}/bin/agent | head -20)"

        # Run the unwrapped binary
        exec ${pkgs.datadog-agent}/bin/.agent-wrapped "$@"
      '';
    in
    {
      script = pkgs.lib.mkForce ''
        export DD_API_KEY=$(head -n 1 /run/datadog-agent/api-key)
        exec ${patchedAgent}/bin/datadog-agent-patched run -c /etc/datadog-agent/datadog.yaml
      '';
      preStart = ''
        mkdir -p /run/datadog-agent
        grep -oP 'DD_API_KEY=\K.*' ${config.age.secrets.datadog-api-key.path} > /run/datadog-agent/api-key
        chmod 600 /run/datadog-agent/api-key
        chown datadog:datadog /run/datadog-agent/api-key
      '';
    };
}
