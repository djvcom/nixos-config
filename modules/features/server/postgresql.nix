# PostgreSQL with secure authentication and monitoring extensions
_:

{
  flake.modules.nixos.postgresql =
    { lib, ... }:
    {
      services.postgresql = {
        enable = true;
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
    };
}
