_:

{
  flake.modules.nixos.roundcube =
    { config, pkgs, ... }:
    let
      desKeyPath = config.age.secrets.roundcube-des-key.path;
      roundcubePort = 8083;
      oauth2Port = 4182;
    in
    {
      services.roundcube = {
        enable = true;
        package = pkgs.roundcube.withPlugins (p: [ p.persistent_login ]);
        hostName = "localhost";

        database = {
          host = "localhost";
          dbname = "roundcube";
          username = "roundcube";
        };

        plugins = [ "persistent_login" ];

        extraConfig = ''
          $config['imap_host'] = 'ssl://mail.djv.sh:993';
          $config['smtp_host'] = 'tls://mail.djv.sh:587';
          $config['smtp_user'] = '%u';
          $config['smtp_pass'] = '%p';

          // Strip domain from username for IMAP/SMTP auth (Stalwart uses username, not email)
          ${"$"}config['username_domain'] = "";
          ${"$"}config['username_domain_forced'] = true;

          // Set mail domain for From address (not mail.djv.sh)
          $config['mail_domain'] = 'djv.sh';

          $config['product_name'] = 'djv.sh Webmail';
          $config['support_url'] = "";

          $config['des_key'] = file_get_contents('${desKeyPath}');

          $config['skin'] = 'elastic';
          $config['language'] = 'en_GB';
        '';
      };

      # nginx listens on localhost only; oauth2-proxy sits in front
      services.nginx.virtualHosts."localhost" = {
        listen = [
          {
            addr = "127.0.0.1";
            port = roundcubePort;
          }
        ];
        forceSSL = false;
        enableACME = false;
      };

      # oauth2-proxy for Roundcube SSO (Kanidm auth before accessing webmail)
      systemd.services.roundcube-oauth2-proxy = {
        description = "OAuth2 Proxy for Roundcube";
        after = [
          "network.target"
          "nginx.service"
        ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = ''
            ${pkgs.oauth2-proxy}/bin/oauth2-proxy \
              --provider=oidc \
              --oidc-issuer-url=https://auth.djv.sh/oauth2/openid/roundcube \
              --client-id=roundcube \
              --redirect-url=https://webmail.djv.sh/oauth2/callback \
              --email-domain=* \
              --upstream=http://127.0.0.1:${toString roundcubePort} \
              --http-address=127.0.0.1:${toString oauth2Port} \
              --cookie-secure=true \
              --cookie-samesite=lax \
              --cookie-name=_roundcube_oauth2 \
              --reverse-proxy=true \
              --skip-provider-button=true \
              --code-challenge-method=S256
          '';
          EnvironmentFile = config.age.secrets.roundcube-oauth2-env.path;
          Restart = "on-failure";
          DynamicUser = true;

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
}
