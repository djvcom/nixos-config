# Kanidm identity provider with passkey support and OIDC clients
{ config, pkgs, ... }:

{
  services.kanidm = {
    enableServer = true;
    package = pkgs.kanidm_1_8.withSecretProvisioning;

    serverSettings = {
      domain = "auth.djv.sh";
      origin = "https://auth.djv.sh";
      bindaddress = "127.0.0.1:8444";

      # TLS certificates from ACME
      tls_chain = "/var/lib/acme/auth.djv.sh/fullchain.pem";
      tls_key = "/var/lib/acme/auth.djv.sh/key.pem";

      # Online backups
      online_backup = {
        path = "/var/backup/kanidm";
        schedule = "00 22 * * *";
        versions = 7;
      };
    };

    # Declarative provisioning
    provision = {
      enable = true;
      adminPasswordFile = config.age.secrets.kanidm-admin-password.path;
      idmAdminPasswordFile = config.age.secrets.kanidm-idm-admin-password.path;

      # Groups for service access
      groups = {
        vaultwarden_users = { };
        openbao_admins = { };
        infrastructure_admins = { };
      };

      # Initial admin user
      persons.dan = {
        displayName = "Dan";
        mailAddresses = [ "dan@djv.sh" ];
        groups = [
          "vaultwarden_users"
          "openbao_admins"
          "infrastructure_admins"
        ];
      };

      # OAuth2/OIDC clients for SSO
      systems.oauth2 = {
        openbao = {
          displayName = "OpenBao Secrets";
          originUrl = "https://bao.djv.sh/";
          originLanding = "https://bao.djv.sh/ui/";
          preferShortUsername = true;
          scopeMaps.openbao_admins = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
        };

        vaultwarden = {
          displayName = "Vaultwarden";
          originUrl = [
            "https://vault.djv.sh/"
            "https://vault.djv.sh/identity/connect/oidc-signin"
          ];
          originLanding = "https://vault.djv.sh/";
          preferShortUsername = true;
          # PKCE is enabled by default in Kanidm; Vaultwarden uses SSO_PKCE=true
          scopeMaps.vaultwarden_users = [
            "openid"
            "profile"
            "email"
          ];
        };
      };
    };
  };

  # Backup directory for Kanidm online backups
  systemd.tmpfiles.rules = [
    "d /var/backup/kanidm 0750 kanidm kanidm -"
  ];

  # ACME certificate for Kanidm (handles TLS termination itself)
  security.acme.certs."auth.djv.sh" = {
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets.cloudflare-dns-token.path;
    group = "kanidm";
  };
}
