# Agenix secrets with proper permissions
_:

{
  age.secrets = {
    datadog-api-key = {
      file = ../../secrets/datadog-api-key.age;
      owner = "datadog";
      group = "datadog";
      mode = "0400";
    };
    datadog-app-key = {
      file = ../../secrets/datadog-app-key.age;
      owner = "datadog";
      group = "datadog";
      mode = "0400";
    };
    datadog-postgres-password = {
      file = ../../secrets/datadog-postgres-password.age;
      owner = "datadog";
      group = "datadog";
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
    kanidm-oauth2-openbao = {
      file = ../../secrets/kanidm-oauth2-openbao.age;
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
    };
    kanidm-oauth2-garage = {
      file = ../../secrets/kanidm-oauth2-garage.age;
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
    };
    garage-env = {
      file = ../../secrets/garage-env.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    garage-webui-env = {
      file = ../../secrets/garage-webui-env.age;
      owner = "garage-webui";
      group = "garage-webui";
      mode = "0400";
    };
    oauth2-proxy-env = {
      file = ../../secrets/oauth2-proxy-env.age;
      owner = "root";
      group = "root";
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
    openbao-oidc-secret = {
      file = ../../secrets/openbao-oidc-secret.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    openbao-oidc-env = {
      file = ../../secrets/openbao-oidc-env.age;
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
    roundcube-des-key = {
      file = ../../secrets/roundcube-des-key.age;
      owner = "roundcube";
      group = "roundcube";
      mode = "0400";
    };

    # Dashboard (Homepage) with SSO
    kanidm-oauth2-dashboard = {
      file = ../../secrets/kanidm-oauth2-dashboard.age;
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
    };
    dashboard-oauth2-env = {
      file = ../../secrets/dashboard-oauth2-env.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # Roundcube OIDC
    kanidm-oauth2-roundcube = {
      file = ../../secrets/kanidm-oauth2-roundcube.age;
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
    };
    roundcube-oauth2-env = {
      file = ../../secrets/roundcube-oauth2-env.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    sidereal-s3-credentials = {
      file = ../../secrets/sidereal-s3-credentials.age;
      owner = "sidereal";
      group = "sidereal";
      mode = "0400";
    };
  };
}
