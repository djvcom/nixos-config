_:

{
  flake.modules.nixos.vaultwarden =
    { config, ... }:
    {
      services.vaultwarden = {
        enable = true;
        dbBackend = "postgresql";
        environmentFile = config.age.secrets.vaultwarden-sso.path;
        config = {
          DOMAIN = "https://vault.djv.sh";
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;
          SIGNUPS_ALLOWED = false;
          INVITATIONS_ALLOWED = true;
          WEBSOCKET_ENABLED = true;
          ADMIN_TOKEN_FILE = config.age.secrets.vaultwarden-admin-token.path;
          DATABASE_URL = "postgresql://vaultwarden@/vaultwarden?host=/run/postgresql";

          SSO_ENABLED = true;
          SSO_AUTHORITY = "https://auth.djv.sh/oauth2/openid/vaultwarden";
          SSO_CLIENT_ID = "vaultwarden";
          SSO_SCOPES = "openid profile email";
          SSO_PKCE = true;
          # SSO_CLIENT_SECRET loaded from environmentFile
        };
      };
    };
}
