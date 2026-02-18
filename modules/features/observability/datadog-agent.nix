_:

{
  flake.modules.nixos.datadog =
    { config, pkgs, ... }:
    let
      extraIntegrations = {
        postgres =
          ps: with ps; [
            azure-identity
            boto3
            mmh3
            pg8000
            psycopg
            psycopg-pool
            psycopg2
            semver
          ];
        redisdb = ps: with ps; [ redis ];
      };

      integrationsEnv = pkgs.datadog-integrations-core extraIntegrations;
    in
    {
      services.datadog-agent = {
        enable = true;
        apiKeyFile = "/run/datadog-agent/api-key";
        hostname = "terminus";
        enableLiveProcessCollection = true;
        inherit extraIntegrations;

        tags = [
          "env:production"
          "host:terminus"
        ];

        checks = {
          ntp = {
            init_config = { };
            instances = [
              {
                hosts = [ "127.0.0.1" ];
                timeout = 1;
              }
            ];
          };
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

        extraConfig = {
          log_level = "INFO";
          database_monitoring = {
            enabled = true;
          };
          cloud_provider_metadata = [ ];
        };
      };

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
              database_autodiscovery:
                enabled: true
                include:
                  - ".*"
              relations:
                - relation_regex: ".*"
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

      users.users.datadog.extraGroups = [ "redis-default" ];

      systemd.services.datadog-agent =
        let
          patchedAgent = pkgs.writeShellScriptBin "datadog-agent-patched" ''
            export PYTHONPATH="${integrationsEnv.python}/${integrationsEnv.python.sitePackages}:${pkgs.datadog-agent}/${pkgs.python313.sitePackages}"
            eval "$(grep -E '^(export )?LD_LIBRARY_PATH' ${pkgs.datadog-agent}/bin/agent | head -20)"
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
    };
}
