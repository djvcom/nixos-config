_:

{
  flake.modules.nixos.dashboard =
    { config, pkgs, ... }:
    let
      dashboardPort = 3010;
      oauth2Port = 4181;
      configDir = "/var/lib/homepage-dashboard";
    in
    {
      systemd = {
        services = {
          # Homepage dashboard service
          homepage-dashboard = {
            description = "Homepage Dashboard";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
              Type = "simple";
              ExecStart = "${pkgs.homepage-dashboard}/bin/homepage";
              WorkingDirectory = configDir;
              DynamicUser = true;
              StateDirectory = "homepage-dashboard";
              Environment = [
                "PORT=${toString dashboardPort}"
                "HOMEPAGE_CONFIG_DIR=${configDir}"
                "HOMEPAGE_ALLOWED_HOSTS=dash.djv.sh"
              ];

              # Systemd hardening
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
              ReadWritePaths = [ configDir ];
            };
          };

          # oauth2-proxy for dashboard SSO (separate instance from Garage's)
          dashboard-oauth2-proxy = {
            description = "OAuth2 Proxy for Dashboard";
            after = [
              "network.target"
              "homepage-dashboard.service"
            ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
              Type = "simple";
              ExecStart = ''
                ${pkgs.oauth2-proxy}/bin/oauth2-proxy \
                  --provider=oidc \
                  --oidc-issuer-url=https://auth.djv.sh/oauth2/openid/dashboard \
                  --client-id=dashboard \
                  --redirect-url=https://dash.djv.sh/oauth2/callback \
                  --email-domain=* \
                  --upstream=http://127.0.0.1:${toString dashboardPort} \
                  --http-address=127.0.0.1:${toString oauth2Port} \
                  --cookie-secure=true \
                  --cookie-samesite=lax \
                  --cookie-name=_dashboard_oauth2 \
                  --reverse-proxy=true \
                  --skip-provider-button=true \
                  --code-challenge-method=S256
              '';
              EnvironmentFile = config.age.secrets.dashboard-oauth2-env.path;
              Restart = "on-failure";
              DynamicUser = true;

              # Systemd hardening
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
        };

        tmpfiles.rules = [
          "d ${configDir} 0755 root root -"
          "d ${configDir}/images 0755 root root -"
          "d ${configDir}/icons 0755 root root -"
        ];
      };

      environment.etc = {
        "homepage-dashboard/settings.yaml" = {
          target = "homepage-dashboard/settings.yaml";
          text = ''
            title: djv.sh
            theme: dark
            color: slate
            headerStyle: clean
            layout:
              Services:
                style: row
                columns: 3
          '';
        };

        "homepage-dashboard/services.yaml" = {
          target = "homepage-dashboard/services.yaml";
          text = ''
            - Services:
                - Vaultwarden:
                    icon: bitwarden
                    href: https://vault.djv.sh
                    description: Password Manager
                - Webmail:
                    icon: roundcube
                    href: https://webmail.djv.sh
                    description: Email
                - Auth:
                    icon: authentik
                    href: https://auth.djv.sh
                    description: Identity Provider
                - Storage:
                    icon: minio
                    href: https://s3.djv.sh/ui/
                    description: S3 Object Storage
                - Secrets:
                    icon: vault
                    href: https://bao.djv.sh
                    description: Secrets Management
                - Mail Admin:
                    icon: mailcow
                    href: https://mail.djv.sh
                    description: Mail Server Admin
          '';
        };

        "homepage-dashboard/widgets.yaml" = {
          target = "homepage-dashboard/widgets.yaml";
          text = ''
            - greeting:
                text_size: xl
                text: Welcome
            - datetime:
                text_size: l
                format:
                  dateStyle: long
                  timeStyle: short
          '';
        };

        # Empty bookmarks.yaml
        "homepage-dashboard/bookmarks.yaml" = {
          target = "homepage-dashboard/bookmarks.yaml";
          text = "";
        };
      };
    };
}
