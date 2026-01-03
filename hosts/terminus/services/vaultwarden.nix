# Vaultwarden password manager (Bitwarden-compatible) with Kanidm SSO
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

      # SSO via Kanidm
      SSO_ENABLED = true;
      SSO_AUTHORITY = "https://auth.djv.sh/oauth2/openid/vaultwarden";
      SSO_CLIENT_ID = "vaultwarden";
      SSO_SCOPES = "openid profile email";
      SSO_PKCE = true;
      SSO_DEBUG_TOKENS = true;
      # SSO_CLIENT_SECRET loaded from environmentFile

      # SMTP via local Stalwart
      SMTP_HOST = "mail.djv.sh";
      SMTP_PORT = 587;
      SMTP_SECURITY = "starttls";
      SMTP_FROM = "vault@djv.sh";
      SMTP_FROM_NAME = "Vaultwarden";
      SMTP_USERNAME = "dan";
      SMTP_PASSWORD_FILE = config.age.secrets.dan-mail-password.path;
    };
  };

  # Add vaultwarden to mail-secrets group for shared credential access
  users.users.vaultwarden.extraGroups = [ "mail-secrets" ];
}
