# Stalwart all-in-one mail server (SMTP, IMAP, JMAP)
{ config, ... }:

{
  services.stalwart-mail = {
    enable = true;
    openFirewall = true;

    settings = {
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

      # Authentication settings
      # SCRAM-SHA-256 preferred; PLAIN fallback for legacy clients (over TLS)
      session.auth = {
        mechanisms = "[scram-sha-256, plain]";
        directory = "'memory'";
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
}
