# Vaultwarden password manager (Bitwarden-compatible)
{ config, ... }:

{
  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    config = {
      DOMAIN = "https://vault.djv.sh";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = true;
      WEBSOCKET_ENABLED = true;
      ADMIN_TOKEN_FILE = config.age.secrets.vaultwarden-admin-token.path;
      DATABASE_URL = "postgresql://vaultwarden@/vaultwarden?host=/run/postgresql";

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
