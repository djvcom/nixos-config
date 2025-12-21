/**
  OpenTelemetry observability module for metrics, traces, and logs collection.

  Configures the OpenTelemetry Collector with:
  - OTLP receivers (gRPC/HTTP) bound to localhost by default
  - Host metrics scraping (CPU, memory, disk, network)
  - Journald log collection (sshd, nginx, nixos-upgrade, etc.)
  - Configurable exporters and pipelines

  Log severity detection:
  - Syslog PRIORITY mapped to OTEL severity (ERROR/WARN/INFO/DEBUG)
  - Message content scanned for "warning|deprecated" -> WARN
  - Message content scanned for "error|failed|failure" -> ERROR
  - Attributes: nixos.upgrade_warning, nixos.build_error

  Security: Receivers bind to localhost only. Use firewall rules to allow
  specific networks (e.g. container networks) access to ports 4317/4318.

  References:
  - OpenTelemetry: <https://opentelemetry.io/docs/collector/>
*/
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.observability;
in
{
  options.modules.observability = {
    enable = lib.mkEnableOption "OpenTelemetry observability";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Address to bind OTLP receivers. Defaults to localhost for security.
        Use 0.0.0.0 only with appropriate firewall rules.
      '';
      example = "0.0.0.0";
    };

    exporters = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      description = "Exporter configurations keyed by exporter name";
      example = lib.literalExpression ''
        {
          datadog = {
            api.key = "\''${env:DD_API_KEY}";
          };
        }
      '';
    };

    pipelines = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      description = "Pipeline configurations defining data flow from receivers through processors to exporters";
      default = {
        metrics = {
          receivers = [ "otlp" "hostmetrics" ];
          processors = [ "resourcedetection" "batch" ];
          exporters = lib.attrNames cfg.exporters;
        };
        traces = {
          receivers = [ "otlp" ];
          processors = [ "resourcedetection" "batch" ];
          exporters = lib.attrNames cfg.exporters;
        };
        logs = {
          receivers = [ "otlp" ];
          processors = [ "resourcedetection" "batch" ];
          exporters = lib.attrNames cfg.exporters;
        };
      };
    };

    tokenSecretPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to agenix-managed secret file containing API tokens as environment variables";
      example = lib.literalExpression "config.age.secrets.datadog-api-key.path";
    };
  };

  config = lib.mkIf cfg.enable {
    services.opentelemetry-collector = {
      enable = true;
      package = pkgs.opentelemetry-collector-contrib;
      settings = {
        receivers = {
          otlp.protocols = {
            grpc.endpoint = "${cfg.listenAddress}:4317";
            http.endpoint = "${cfg.listenAddress}:4318";
          };
          hostmetrics = {
            collection_interval = "10s";
            scrapers = {
              cpu.metrics = {
                "system.cpu.utilization".enabled = true;
                "system.cpu.physical.count".enabled = true;
                "system.cpu.logical.count".enabled = true;
              };
              disk = {};
              filesystem.metrics = {
                "system.filesystem.utilization".enabled = true;
              };
              load = {};
              memory = {};
              network = {};
              paging.metrics = {
                "system.paging.utilization".enabled = true;
              };
              processes = {};
            };
          };
          journald = {
            units = [ "sshd" "nginx" "docker" "podman" "systemd-*" "nixos-upgrade" "nixos-upgrade-preflight" ];
            priority = "info";
          };
        };
        processors = {
          batch.timeout = "10s";
          resourcedetection = {
            detectors = [ "system" ];
            system.hostname_sources = [ "os" ];
          };
          "transform/logs" = {
            log_statements = [
              {
                context = "log";
                statements = [
                  ''merge_maps(attributes, body, "insert")''
                  ''set(attributes["message"], body["MESSAGE"])''
                  ''set(attributes["service"], body["SYSLOG_IDENTIFIER"])''
                  # Set severity based on syslog PRIORITY first
                  ''set(severity_number, SEVERITY_NUMBER_ERROR) where body["PRIORITY"] == "3"''
                  ''set(severity_number, SEVERITY_NUMBER_WARN) where body["PRIORITY"] == "4"''
                  ''set(severity_number, SEVERITY_NUMBER_INFO) where body["PRIORITY"] == "5"''
                  ''set(severity_number, SEVERITY_NUMBER_INFO) where body["PRIORITY"] == "6"''
                  ''set(severity_number, SEVERITY_NUMBER_DEBUG) where body["PRIORITY"] == "7"''
                  # Override: flag warnings/deprecations in message content (e.g. nix build output)
                  ''set(attributes["nixos.upgrade_warning"], true) where IsMatch(body["MESSAGE"], "(?i)warning|deprecated")''
                  ''set(severity_number, SEVERITY_NUMBER_WARN) where IsMatch(body["MESSAGE"], "(?i)warning|deprecated")''
                  # Override: flag errors in message content (errors take precedence over warnings)
                  ''set(attributes["nixos.build_error"], true) where IsMatch(body["MESSAGE"], "(?i)\\berror\\b|\\bfailed\\b|\\bfailure\\b")''
                  ''set(severity_number, SEVERITY_NUMBER_ERROR) where IsMatch(body["MESSAGE"], "(?i)\\berror\\b|\\bfailed\\b|\\bfailure\\b")''
                  ''set(body, body["MESSAGE"])''
                ];
              }
            ];
          };
        };
        exporters = cfg.exporters;
        service.pipelines = cfg.pipelines;
      };
    };

    systemd.services.opentelemetry-collector.serviceConfig = lib.mkIf (cfg.tokenSecretPath != null) {
      EnvironmentFile = cfg.tokenSecretPath;
      SupplementaryGroups = [ "systemd-journal" ];
    };
  };
}
