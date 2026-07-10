_:

{
  flake.modules.nixos.garage =
    { config, pkgs, ... }:
    {
      services.garage = {
        enable = true;
        package = pkgs.garage;

        settings = {
          metadata_dir = "/var/lib/garage/meta";
          data_dir = "/var/lib/garage/data";
          db_engine = "sqlite";

          replication_factor = 1; # Single node

          rpc_bind_addr = "127.0.0.1:3901";
          rpc_public_addr = "127.0.0.1:3901";

          s3_api = {
            s3_region = "garage";
            api_bind_addr = "127.0.0.1:3900";
            root_domain = ".s3.djv.sh";
          };

          admin = {
            api_bind_addr = "127.0.0.1:3903";
            trace_sink = "http://127.0.0.1:4317";
          };
        };

        environmentFile = config.age.secrets.garage-env.path;
      };
    };
}
