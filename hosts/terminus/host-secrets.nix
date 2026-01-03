# Agenix secrets with proper permissions
_:

{
  age.secrets = {
    datadog-api-key = {
      file = ../../secrets/datadog-api-key.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    datadog-app-key = {
      file = ../../secrets/datadog-app-key.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    minio-credentials = {
      file = ../../secrets/minio-credentials.age;
      owner = "minio";
      group = "minio";
      mode = "0400";
    };
    cloudflare-dns-token = {
      file = ../../secrets/cloudflare-dns-token.age;
      owner = "acme";
      group = "traefik";
      mode = "0440";
    };
    git-identity = {
      file = ../../secrets/git-identity.age;
      path = "/home/dan/.config/git/identity";
      owner = "dan";
      group = "users";
      mode = "0400";
    };
    kanidm-admin-password = {
      file = ../../secrets/kanidm-admin-password.age;
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
    };
    kanidm-idm-admin-password = {
      file = ../../secrets/kanidm-idm-admin-password.age;
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
    };
    kanidm-oauth2-vaultwarden = {
      file = ../../secrets/kanidm-oauth2-vaultwarden.age;
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
    };
    vaultwarden-admin-token = {
      file = ../../secrets/vaultwarden-admin-token.age;
      owner = "vaultwarden";
      group = "vaultwarden";
      mode = "0400";
    };
    vaultwarden-sso = {
      file = ../../secrets/vaultwarden-sso.age;
      owner = "vaultwarden";
      group = "vaultwarden";
      mode = "0400";
    };
    stalwart-admin-password = {
      file = ../../secrets/stalwart-admin-password.age;
      owner = "stalwart-mail";
      group = "stalwart-mail";
      mode = "0400";
    };
    dkim-rsa-key = {
      file = ../../secrets/dkim-rsa-key.age;
      owner = "stalwart-mail";
      group = "stalwart-mail";
      mode = "0400";
    };
    dkim-ed25519-key = {
      file = ../../secrets/dkim-ed25519-key.age;
      owner = "stalwart-mail";
      group = "stalwart-mail";
      mode = "0400";
    };
    dan-mail-password = {
      file = ../../secrets/dan-mail-password.age;
      owner = "root";
      group = "mail-secrets";
      mode = "0440";
    };
    openbao-keys = {
      file = ../../secrets/openbao-keys.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    backup-credentials = {
      file = ../../secrets/backup-credentials.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
}
