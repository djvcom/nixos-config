_:

{
  flake.modules.nixos.kanidm =
    { config, pkgs, ... }:
    {
      services.kanidm = {
        server.enable = true;
        package = pkgs.kanidm_1_8.withSecretProvisioning;

        server.settings = {
          domain = "auth.djv.sh";
          origin = "https://auth.djv.sh";
          bindaddress = "127.0.0.1:8444";

          tls_chain = "/var/lib/acme/auth.djv.sh/fullchain.pem";
          tls_key = "/var/lib/acme/auth.djv.sh/key.pem";

          online_backup = {
            path = "/var/backup/kanidm";
            schedule = "00 22 * * *";
            versions = 7;
          };
        };

        provision = {
          enable = true;
          adminPasswordFile = config.age.secrets.kanidm-admin-password.path;
          idmAdminPasswordFile = config.age.secrets.kanidm-idm-admin-password.path;

          groups = {
            vaultwarden_users = { };
            openbao_admins = { };
            infrastructure_admins = { };
            garage_users = { };
            dashboard_users = { };
            mail_users = { };
          };

          persons.dan = {
            displayName = "Dan";
            mailAddresses = [ "dan@djv.sh" ];
            groups = [
              "vaultwarden_users"
              "openbao_admins"
              "infrastructure_admins"
              "garage_users"
              "dashboard_users"
              "mail_users"
            ];
          };

          systems.oauth2 = {
            openbao = {
              displayName = "OpenBao Secrets";
              originUrl = [
                "https://bao.djv.sh/"
                "https://bao.djv.sh/ui/vault/auth/oidc/oidc/callback"
              ];
              originLanding = "https://bao.djv.sh/ui/";
              basicSecretFile = config.age.secrets.kanidm-oauth2-openbao.path;
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
              basicSecretFile = config.age.secrets.kanidm-oauth2-vaultwarden.path;
              preferShortUsername = true;
              # PKCE is enabled by default in Kanidm; Vaultwarden uses SSO_PKCE=true
              scopeMaps.vaultwarden_users = [
                "openid"
                "profile"
                "email"
              ];
            };

            garage = {
              displayName = "Garage Storage";
              originUrl = [
                "https://garage.djv.sh/"
                "https://garage.djv.sh/oauth2/callback"
              ];
              originLanding = "https://garage.djv.sh/";
              basicSecretFile = config.age.secrets.kanidm-oauth2-garage.path;
              preferShortUsername = true;
              scopeMaps.garage_users = [
                "openid"
                "profile"
                "email"
              ];
            };

            dashboard = {
              displayName = "Dashboard";
              originUrl = [
                "https://dash.djv.sh/"
                "https://dash.djv.sh/oauth2/callback"
              ];
              originLanding = "https://dash.djv.sh/";
              basicSecretFile = config.age.secrets.kanidm-oauth2-dashboard.path;
              preferShortUsername = true;
              scopeMaps.dashboard_users = [
                "openid"
                "profile"
                "email"
              ];
            };

            roundcube = {
              displayName = "Webmail";
              originUrl = [
                "https://webmail.djv.sh/"
                "https://webmail.djv.sh/oauth2/callback"
              ];
              originLanding = "https://webmail.djv.sh/";
              basicSecretFile = config.age.secrets.kanidm-oauth2-roundcube.path;
              preferShortUsername = true;
              scopeMaps.mail_users = [
                "openid"
                "profile"
                "email"
              ];
            };
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/backup/kanidm 0750 kanidm kanidm -"
      ];

      # ACME certificate for Kanidm (handles TLS termination itself)
      security.acme.certs."auth.djv.sh" = {
        dnsProvider = "cloudflare";
        environmentFile = config.age.secrets.cloudflare-dns-token.path;
        group = "kanidm";
      };

      systemd.services.kanidm.serviceConfig = {
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        NoNewPrivileges = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        ReadWritePaths = [
          "/var/lib/kanidm"
          "/var/lib/acme"
          "/var/backup/kanidm"
        ];
      };
    };
}
