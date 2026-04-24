_:

{
  flake.modules.nixos.terminus =
    { config, ... }:
    {
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

    };
}
