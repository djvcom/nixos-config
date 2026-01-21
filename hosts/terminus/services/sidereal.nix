# Sidereal service
#
# Localhost-only for development and testing.
# Uses shared PostgreSQL, Valkey, and Garage (S3) instances.
{
  config,
  inputs,
  pkgs,
  ...
}:

{
  services.sidereal = {
    enable = true;

    # Provide package explicitly (overlay requires rust-bin we don't have)
    package = inputs.sidereal.packages.${pkgs.stdenv.hostPlatform.system}.sidereal-server;

    # Localhost-only access for development
    gateway.listenAddress = "127.0.0.1:8422";

    # Use shared PostgreSQL via Unix socket (peer auth)
    database = {
      createLocally = true;
      url = "postgres:///sidereal?host=/run/postgresql";
    };

    # Use shared Valkey instance
    valkey.createLocally = false;
    valkey.url = "redis://127.0.0.1:6379";

    # Use Garage for S3 storage
    storage = {
      backend = "s3";
      endpoint = "http://127.0.0.1:3900";
      bucket = "sidereal";
      credentialsFile = config.age.secrets.sidereal-s3-credentials.path;
    };
  };
}
