# Valkey in-memory data store
#
# Redis-compatible key/value store for caching and persistent data.
# Uses the Redis NixOS module with Valkey as a drop-in replacement.
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
      # Uses module's default path: /run/redis-default/redis.sock
      unixSocket = "/run/redis-default/redis.sock";
      unixSocketPerm = 660;

      # Persistence: RDB snapshots + AOF for durability
      # RDB: save after 900s if 1 key changed, 300s if 10 keys, 60s if 10000 keys
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

      # AOF (Append Only File) for better durability
      appendOnly = true;
      appendFsync = "everysec";

      settings = {
        # Memory management
        maxmemory = "256mb";
        maxmemory-policy = "allkeys-lru";

        # Performance tuning
        tcp-keepalive = 300;
        timeout = 0;

        # Logging
        loglevel = "notice";
      };
    };
  };
}
