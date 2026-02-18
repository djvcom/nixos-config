_:

{
  flake.modules.nixos.valkey =
    { pkgs, ... }:
    {
      services.redis = {
        package = pkgs.valkey;
        vmOverCommit = true;

        servers.default = {
          enable = true;
          bind = "127.0.0.1";
          port = 6379;

          # Unix socket for local services (more secure, slightly faster)
          unixSocket = "/run/redis-default/redis.sock";
          unixSocketPerm = 660;

          save = [
            [
              900
              1
            ]
            [
              300
              10
            ]
            [
              60
              10000
            ]
          ];

          appendOnly = true;
          appendFsync = "everysec";

          settings = {
            maxmemory = "256mb";
            maxmemory-policy = "allkeys-lru";

            tcp-keepalive = 300;
            timeout = 0;

            loglevel = "notice";
          };
        };
      };
    };
}
