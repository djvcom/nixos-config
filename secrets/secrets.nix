let
  terminus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPGskDEvecbqILMi3BN755k2pg6S+2ctewH66YWdpX5H";
  dan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHifaRXUcEaoTkf8dJF4qB7V9+VTjYX++fRbOKoCCpC2";
  allKeys = [
    terminus
    dan
  ];
in
{
  "git-identity.age".publicKeys = allKeys;
  "wireguard-private.age".publicKeys = allKeys;
  "datadog-api-key.age".publicKeys = allKeys;
  "datadog-app-key.age".publicKeys = allKeys;
  "cloudflare-dns-token.age".publicKeys = allKeys;

  # Garage S3-compatible storage
  "garage-env.age".publicKeys = allKeys;
  "garage-webui-env.age".publicKeys = allKeys;
  "kanidm-oauth2-garage.age".publicKeys = allKeys;
  "oauth2-proxy-env.age".publicKeys = allKeys;

  # Kanidm identity provider
  "kanidm-admin-password.age".publicKeys = allKeys;
  "kanidm-idm-admin-password.age".publicKeys = allKeys;

  # Vaultwarden password manager
  "vaultwarden-admin-token.age".publicKeys = allKeys;
  "vaultwarden-sso.age".publicKeys = allKeys;

  # Kanidm OAuth2 client secrets
  "kanidm-oauth2-vaultwarden.age".publicKeys = allKeys;
  "kanidm-oauth2-openbao.age".publicKeys = allKeys;

  # Stalwart mail server
  "stalwart-admin-password.age".publicKeys = allKeys;
  "dkim-rsa-key.age".publicKeys = allKeys;
  "dkim-ed25519-key.age".publicKeys = allKeys;
  "dan-mail-password.age".publicKeys = allKeys;

  # OpenBao secrets management
  "openbao-keys.age".publicKeys = allKeys;
  "openbao-oidc-secret.age".publicKeys = allKeys;
  "openbao-oidc-env.age".publicKeys = allKeys;

  # Backup system
  "backup-credentials.age".publicKeys = allKeys;

  # Datadog monitoring
  "datadog-postgres-password.age".publicKeys = allKeys;

  # Roundcube webmail
  "roundcube-des-key.age".publicKeys = allKeys;

  # Dashboard (Homepage)
  "kanidm-oauth2-dashboard.age".publicKeys = allKeys;
  "dashboard-oauth2-env.age".publicKeys = allKeys;

  # Roundcube OIDC
  "kanidm-oauth2-roundcube.age".publicKeys = allKeys;
  "roundcube-oauth2-env.age".publicKeys = allKeys;
}
