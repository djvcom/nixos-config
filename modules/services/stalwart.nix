# Stalwart all-in-one mail server (SMTP, IMAP, JMAP)
_:

{
  flake.modules.nixos.stalwart =
    { config, ... }:
    {
      services.stalwart-mail = {
        enable = true;
        # HTTP listener is localhost-only, Traefik handles external; mail ports opened explicitly below
        openFirewall = false;

        settings = {
          # OpenTelemetry tracing
          tracer.otel = {
            type = "open-telemetry";
            transport = "grpc";
            endpoint = "http://127.0.0.1:4317";
            level = "info";
            enable = true;
          };

          server = {
            hostname = "mail.djv.sh";

            tls = {
              enable = true;
              implicit = true;
            };

            listener = {
              # SMTP for incoming mail from other servers (STARTTLS)
              smtp = {
                bind = [ "[::]:25" ];
                protocol = "smtp";
              };

              # SMTP submission (authenticated users)
              smtp-submission = {
                bind = [ "[::]:587" ];
                protocol = "smtp";
              };

              # SMTPS (implicit TLS)
              smtps = {
                bind = [ "[::]:465" ];
                protocol = "smtp";
                tls.implicit = true;
              };

              # IMAPS (implicit TLS)
              imaps = {
                bind = [ "[::]:993" ];
                protocol = "imap";
                tls.implicit = true;
              };

              # HTTP for JMAP/admin API (behind Traefik)
              http = {
                bind = [ "127.0.0.1:8082" ];
                protocol = "http";
              };
            };
          };

          # Use ACME certificates
          certificate.default = {
            cert = "%{file:/var/lib/acme/mail.djv.sh/fullchain.pem}%";
            private-key = "%{file:/var/lib/acme/mail.djv.sh/key.pem}%";
            default = true;
          };

          # Storage configuration - single RocksDB store for all data
          store.data = {
            type = "rocksdb";
            path = "/var/lib/stalwart-mail/data";
          };

          storage = {
            data = "data";
            blob = "data";
            fts = "data";
            lookup = "data";
            directory = "memory";
          };

          # In-memory directory with declarative users
          directory."memory" = {
            type = "memory";
            principals = [
              {
                class = "individual";
                name = "dan";
                secret = "%{file:${config.age.secrets.dan-mail-password.path}}%";
                email = [
                  "dan@djv.sh"
                  "postmaster@djv.sh"
                  "admin@djv.sh"
                  "vault@djv.sh"
                  "noreply@djv.sh"
                ];
              }
            ];
          };

          # DKIM signatures for outgoing mail
          signature."rsa" = {
            private-key = "%{file:${config.age.secrets.dkim-rsa-key.path}}%";
            domain = "djv.sh";
            selector = "mail";
            headers = [
              "From"
              "To"
              "Date"
              "Subject"
              "Message-ID"
            ];
            algorithm = "rsa-sha256";
            canonicalization = "relaxed/relaxed";
            expire = "10d";
            report = true;
          };

          signature."ed25519" = {
            private-key = "%{file:${config.age.secrets.dkim-ed25519-key.path}}%";
            domain = "djv.sh";
            selector = "ed";
            headers = [
              "From"
              "To"
              "Date"
              "Subject"
              "Message-ID"
            ];
            algorithm = "ed25519-sha256";
            canonicalization = "relaxed/relaxed";
            expire = "10d";
            report = true;
          };

          # Sign outgoing mail with both RSA and ED25519
          # Only sign mail from authenticated users (not incoming)
          auth.dkim.sign = [
            {
              "if" = "listener != 'smtp'";
              "then" = "['rsa', 'ed25519']";
            }
            { "else" = false; }
          ];

          # IMAP authentication - point to memory directory where users are defined
          imap.auth = {
            mechanisms = [ "plain" ];
            directory = "memory";
          };

          # Admin fallback account
          authentication.fallback-admin = {
            user = "admin";
            secret = "%{file:${config.age.secrets.stalwart-admin-password.path}}%";
          };
        };
      };

      # Add stalwart-mail to mail-secrets group for shared credential access
      users.users.stalwart-mail.extraGroups = [ "mail-secrets" ];

      # ACME certificate for mail server TLS
      security.acme.certs."mail.djv.sh" = {
        dnsProvider = "cloudflare";
        environmentFile = config.age.secrets.cloudflare-dns-token.path;
        group = "stalwart-mail";
      };

      # Open mail ports explicitly (HTTP 8082 stays localhost-only behind Traefik)
      networking.firewall.allowedTCPPorts = [
        25 # SMTP
        587 # SMTP submission
        465 # SMTPS
        993 # IMAPS
      ];

      # Restart when secrets change (credentials are cached at startup)
      systemd.services.stalwart-mail.restartTriggers = [
        config.age.secrets.dan-mail-password.file
        config.age.secrets.stalwart-admin-password.file
        config.age.secrets.dkim-rsa-key.file
        config.age.secrets.dkim-ed25519-key.file
      ];

      # Systemd hardening for stalwart-mail
      systemd.services.stalwart-mail.serviceConfig = {
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
        ReadWritePaths = [
          "/var/lib/stalwart-mail"
          "/var/lib/acme"
        ];
      };
    };
}
