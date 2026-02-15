# Terminus-specific observability pipeline and Datadog PostgreSQL monitoring
_:

{
  flake.modules.nixos.terminus =
    {
      config,
      pkgs,
      ...
    }:
    {
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

      # Configure PostgreSQL datadog user for Database Monitoring
      systemd.services.postgresql-datadog-setup = {
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
}
