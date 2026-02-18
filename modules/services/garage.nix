_:

{
  flake.modules.nixos.garage =
    { config, pkgs, ... }:
    {
      users.users.garage-webui = {
        isSystemUser = true;
        group = "garage-webui";
      };
      users.groups.garage-webui = { };

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

      systemd.services.garage-webui = {
        description = "Garage Web UI";
        after = [ "garage.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = "${pkgs.garage-webui}/bin/garage-webui";
          User = "garage-webui";
          Group = "garage-webui";
          Environment = [
            "CONFIG_PATH=/etc/garage.toml"
            "API_BASE_URL=http://127.0.0.1:3903"
            "S3_ENDPOINT_URL=http://127.0.0.1:3900"
            "PORT=3902"
          ];
          EnvironmentFile = config.age.secrets.garage-webui-env.path;

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
        };
      };

      services.oauth2-proxy = {
        enable = true;

        provider = "oidc";
        clientID = "garage";
        keyFile = config.age.secrets.oauth2-proxy-env.path;

        cookie.secure = true;

        extraConfig = {
          oidc-issuer-url = "https://auth.djv.sh/oauth2/openid/garage";
          redirect-url = "https://garage.djv.sh/oauth2/callback";
          email-domain = "*";
          upstream = "http://127.0.0.1:3902";
          http-address = "127.0.0.1:4180";
          reverse-proxy = true;
          skip-provider-button = true;
          set-xauthrequest = true;
          code-challenge-method = "S256"; # Required for Kanidm PKCE
          # Skip auth for static assets fetched during OAuth redirect flow
          skip-auth-regex = "^/(site\\.webmanifest|favicon.*|apple-touch-icon.*|assets/.*)$";
        };
      };
    };
}
