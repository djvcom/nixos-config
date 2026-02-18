_:

{
  flake.modules.nixos.terminus =
    { config, ... }:
    {
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
    };
}
