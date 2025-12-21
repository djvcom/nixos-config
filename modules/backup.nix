/**
  Automated backup module using restic with optional PostgreSQL support.

  Features:
  - Encrypted backups to S3-compatible storage
  - Automatic PostgreSQL database dumps
  - Configurable retention policies
  - Scheduled execution with randomised delay

  References:
  - Restic: <https://restic.readthedocs.io/>
  - PostgreSQL backup: <https://www.postgresql.org/docs/current/backup-dump.html>
*/
{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.backup;
in
{
  options.modules.backup = {
    enable = lib.mkEnableOption "automated backups with restic";

    repository = lib.mkOption {
      type = lib.types.str;
      description = "Restic repository URL (S3, B2, local path, etc.)";
      example = "s3:https://s3.example.com/bucket-name";
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Filesystem paths to include in backup";
      example = lib.literalExpression ''[ "/home" "/var/lib/important" ]'';
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "**/.cache"
        "**/node_modules"
        "**/target/debug"
        "**/target/release"
        "**/.git"
      ];
      description = "Glob patterns to exclude from backup";
    };

    postgresqlDatabases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "PostgreSQL databases to dump before backup";
      example = lib.literalExpression ''[ "myapp" "nextcloud" ]'';
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "Backup schedule in {manpage}`systemd.time(7)` calendar format";
      example = "hourly";
    };

    retention = lib.mkOption {
      description = "Backup retention policy (how many snapshots to keep)";
      type = lib.types.submodule {
        options = {
          daily = lib.mkOption {
            type = lib.types.int;
            default = 7;
            description = "Number of daily snapshots to retain";
          };
          weekly = lib.mkOption {
            type = lib.types.int;
            default = 4;
            description = "Number of weekly snapshots to retain";
          };
          monthly = lib.mkOption {
            type = lib.types.int;
            default = 6;
            description = "Number of monthly snapshots to retain";
          };
        };
      };
      default = { };
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to environment file containing:
        - RESTIC_PASSWORD: Repository encryption password
        - Cloud credentials (AWS_ACCESS_KEY_ID, etc.)
      '';
      example = lib.literalExpression "config.age.secrets.restic-env.path";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.environmentFile != null;
        message = "modules.backup.environmentFile must be set";
      }
      {
        assertion = cfg.paths != [ ] || cfg.postgresqlDatabases != [ ];
        message = "modules.backup: either paths or postgresqlDatabases must be set";
      }
    ];

    services.postgresqlBackup = lib.mkIf (cfg.postgresqlDatabases != [ ]) {
      enable = true;
      databases = cfg.postgresqlDatabases;
      location = "/var/backup/postgresql";
      startAt = "*-*-* 03:00:00";
    };

    services.restic.backups.main = {
      initialize = true;
      paths = cfg.paths ++ lib.optional (cfg.postgresqlDatabases != [ ]) "/var/backup/postgresql";
      inherit (cfg) repository environmentFile;

      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "30min";
      };

      pruneOpts = [
        "--keep-daily ${toString cfg.retention.daily}"
        "--keep-weekly ${toString cfg.retention.weekly}"
        "--keep-monthly ${toString cfg.retention.monthly}"
      ];

      backupPrepareCommand = ''
        echo "Starting backup at $(date)"
      '';

      backupCleanupCommand = ''
        echo "Backup completed at $(date)"
      '';

      inherit (cfg) exclude;
    };

    systemd.tmpfiles.rules = lib.mkIf (cfg.postgresqlDatabases != [ ]) [
      "d /var/backup/postgresql 0700 postgres postgres -"
    ];
  };
}
