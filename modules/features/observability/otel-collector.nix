# OpenTelemetry observability module (wraps NixOS module options)
_:

{
  flake.modules.nixos.observability =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.modules.observability;
    in
    {
      options.modules.observability = {
        enable = lib.mkEnableOption "OpenTelemetry observability";

        hostname = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Hostname for all telemetry sent to Datadog";
          example = "terminus";
        };

        listenAddress = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Address to bind OTLP receivers";
          example = "0.0.0.0";
        };

        exporters = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          description = "Exporter configurations keyed by exporter name";
        };

        pipelines = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          description = "Pipeline configurations";
          default = {
            metrics = {
              receivers = [
                "otlp"
                "hostmetrics"
              ];
              processors = [
                "resourcedetection"
                "batch"
              ];
              exporters = lib.attrNames cfg.exporters;
            };
            traces = {
              receivers = [ "otlp" ];
              processors = [
                "resourcedetection"
                "batch"
              ];
              exporters = lib.attrNames cfg.exporters;
            };
            logs = {
              receivers = [ "otlp" ];
              processors = [
                "resourcedetection"
                "batch"
              ];
              exporters = lib.attrNames cfg.exporters;
            };
          };
        };

        tokenSecretPath = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to agenix-managed secret file containing API tokens";
        };

        extensions = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "Extension configurations keyed by extension name";
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
                  disk = { };
                  filesystem = {
                    exclude_mount_points = {
                      mount_points = [
                        "/var/lib/containers/*"
                        "/run/containers/*"
                      ];
                      match_type = "regexp";
                    };
                    metrics = {
                      "system.filesystem.utilization".enabled = true;
                    };
                  };
                  load = { };
                  memory = { };
                  network = { };
                  paging.metrics = {
                    "system.paging.utilization".enabled = true;
                  };
                  processes = { };
                };
              };
              journald = {
                units = [
                  "sshd"
                  "traefik"
                  "djv"
                  "docker"
                  "podman"
                  "systemd-*"
                  "nixos-upgrade"
                  "nixos-upgrade-preflight"
                  "stalwart"
                  "garage"
                  "oauth2-proxy"
                ];
                priority = "info";
              };
            };
            processors = {
              batch.timeout = "10s";
              resourcedetection = {
                detectors = [ "system" ];
                system.hostname_sources = [ "os" ];
              };
            }
            // lib.optionalAttrs (cfg.hostname != null) {
              "transform/hostname" = {
                metric_statements = [
                  {
                    context = "resource";
                    statements = [ ''set(attributes["datadog.host.name"], "${cfg.hostname}")'' ];
                  }
                ];
                trace_statements = [
                  {
                    context = "resource";
                    statements = [ ''set(attributes["datadog.host.name"], "${cfg.hostname}")'' ];
                  }
                ];
                log_statements = [
                  {
                    context = "resource";
                    statements = [ ''set(attributes["datadog.host.name"], "${cfg.hostname}")'' ];
                  }
                ];
              };
            }
            // {
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
                      ''set(attributes["nixos.upgrade_warning"], true) where IsMatch(body["MESSAGE"], "(?i)warning|deprecated")''
                      ''set(severity_number, SEVERITY_NUMBER_WARN) where IsMatch(body["MESSAGE"], "(?i)warning|deprecated")''
                      ''set(attributes["nixos.build_error"], true) where IsMatch(body["MESSAGE"], "(?i)\\berror\\b|\\bfailed\\b|\\bfailure\\b")''
                      ''set(severity_number, SEVERITY_NUMBER_ERROR) where IsMatch(body["MESSAGE"], "(?i)\\berror\\b|\\bfailed\\b|\\bfailure\\b")''
                      ''set(body, body["MESSAGE"])''
                    ];
                  }
                ];
              };
            };
            inherit (cfg) exporters extensions;
            service = {
              inherit (cfg) pipelines;
              extensions = lib.attrNames cfg.extensions;
            };
          };
        };

        systemd.services.opentelemetry-collector.serviceConfig = lib.mkIf (cfg.tokenSecretPath != null) {
          EnvironmentFile = cfg.tokenSecretPath;
          SupplementaryGroups = [ "systemd-journal" ];
        };
      };
    };
}
