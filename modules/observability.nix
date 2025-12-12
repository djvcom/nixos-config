{ config, lib, pkgs, ... }:

let
  cfg = config.modules.observability;
in
{
  options.modules.observability = {
    enable = lib.mkEnableOption "OpenTelemetry observability";

    exporters = lib.mkOption {
      type = lib.types.attrs;
      description = "OTEL exporter configuration";
    };

    pipelines = lib.mkOption {
      type = lib.types.attrs;
      description = "OTEL pipeline configuration";
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
      description = "Path to agenix secret for API token";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 4317 4318 ];

    services.opentelemetry-collector = {
      enable = true;
      package = pkgs.opentelemetry-collector-contrib;
      settings = {
        receivers = {
          otlp.protocols = {
            grpc.endpoint = "0.0.0.0:4317";
            http.endpoint = "0.0.0.0:4318";
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
            units = [ "sshd" "nginx" "docker" "podman" "systemd-*" ];
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
                  ''set(severity_number, SEVERITY_NUMBER_ERROR) where body["PRIORITY"] == "3"''
                  ''set(severity_number, SEVERITY_NUMBER_WARN) where body["PRIORITY"] == "4"''
                  ''set(severity_number, SEVERITY_NUMBER_INFO) where body["PRIORITY"] == "5"''
                  ''set(severity_number, SEVERITY_NUMBER_INFO) where body["PRIORITY"] == "6"''
                  ''set(severity_number, SEVERITY_NUMBER_DEBUG) where body["PRIORITY"] == "7"''
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
