{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Domain configuration - used by both Traefik and ACME
  domains = {
    djv = {
      host = "djv.sh";
      backend = "http://127.0.0.1:7823";
    };
    minioApi = {
      host = "state.djv.sh";
      backend = "http://127.0.0.1:9000";
    };
    minioConsole = {
      host = "minio.djv.sh";
      backend = "http://127.0.0.1:9001";
    };
    kanidm = {
      host = "auth.djv.sh";
      backend = "https://127.0.0.1:8444";
    };
    vaultwarden = {
      host = "vault.djv.sh";
      backend = "http://127.0.0.1:8222";
    };
    openbao = {
      host = "bao.djv.sh";
      backend = "http://127.0.0.1:8200";
    };
    stalwart = {
      host = "mail.djv.sh";
      backend = "http://127.0.0.1:8082";
    };
  };

  # Security headers for all responses - see SECURITY.md for OWASP references
  # Must be included in any location block that uses add_header (nginx inheritance quirk)
  securityHeaders = ''
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
  '';

  # Helper for nginx virtual hosts
  mkVhost =
    {
      acmeHost,
      proxyTo ? null,
      extraLocationConfig ? "",
    }:
    {
      listen = [
        {
          addr = "127.0.0.1";
          port = 8443;
          ssl = true;
        }
      ];
      useACMEHost = acmeHost;
      addSSL = true;
      locations."/" =
        if proxyTo != null then
          {
            proxyPass = proxyTo;
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              ${securityHeaders}
              ${extraLocationConfig}
            '';
          }
        else
          {
            return = "200 'Welcome to djv.sh'";
            extraConfig = ''
              default_type text/plain;
              ${securityHeaders}
            '';
          };
    };
in
{
  imports = [
    ./hardware.nix
    ../../modules/base.nix
    ../../modules/observability.nix
  ];

  networking = {
    hostName = "terminus";
    useDHCP = false;
    interfaces.eth0 = {
      ipv4.addresses = [
        {
          address = "88.99.1.188";
          prefixLength = 24;
        }
      ];
      ipv6.addresses = [
        {
          address = "2a01:4f8:173:28ab::2";
          prefixLength = 64;
        }
      ];
    };
    nameservers = [
      "185.12.64.1"
      "185.12.64.2"
    ];
    defaultGateway = "88.99.1.129";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        443
      ];
      allowPing = true;
      logRefusedConnections = true;
      # Allow OTEL ports only from Docker network
      extraCommands = ''
        iptables -I nixos-fw 5 -p tcp -s 172.17.0.0/16 --dport 4317 -j nixos-fw-accept
        iptables -I nixos-fw 5 -p tcp -s 172.17.0.0/16 --dport 4318 -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -D nixos-fw -p tcp -s 172.17.0.0/16 --dport 4317 -j nixos-fw-accept 2>/dev/null || true
        iptables -D nixos-fw -p tcp -s 172.17.0.0/16 --dport 4318 -j nixos-fw-accept 2>/dev/null || true
      '';
    };
  };

  # Kernel and network hardening - see SECURITY.md for CIS/NIST references
  boot = {
    kernelModules = [
      "kvm-intel"
      "kvm-amd"
      "iptable_nat"
      "iptable_filter"
    ];
    swraid.mdadmConf = "MAILADDR root";
    kernel.sysctl = {
      # Prevent SYN flood attacks
      "net.ipv4.tcp_syncookies" = 1;

      # Disable ICMP redirects
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;

      # Don't send ICMP redirects
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;

      # Enable reverse path filtering
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;

      # Log martian packets
      "net.ipv4.conf.all.log_martians" = 1;

      # Restrict kernel pointer exposure
      "kernel.kptr_restrict" = 2;

      # Restrict dmesg to root
      "kernel.dmesg_restrict" = 1;

      # Restrict perf_event_open
      "kernel.perf_event_paranoid" = 3;

      # Restrict BPF
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
    };
  };

  # Secrets - with proper permissions
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
      mode = "0440";
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
    vaultwarden-admin-token = {
      file = ../../secrets/vaultwarden-admin-token.age;
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
      group = "root";
      mode = "0444";
    };
    openbao-keys = {
      file = ../../secrets/openbao-keys.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  modules.observability = {
    enable = true;
    tokenSecretPath = config.age.secrets.datadog-api-key.path;
    exporters = {
      datadog = {
        api.key = "\${env:DD_API_KEY}";
      };
    };
    pipelines = {
      metrics = {
        receivers = [
          "otlp"
          "hostmetrics"
        ];
        processors = [
          "resourcedetection"
          "batch"
        ];
        exporters = [ "datadog" ];
      };
      traces = {
        receivers = [ "otlp" ];
        processors = [
          "resourcedetection"
          "batch"
        ];
        exporters = [ "datadog" ];
      };
      logs = {
        receivers = [ "otlp" ];
        processors = [
          "resourcedetection"
          "batch"
        ];
        exporters = [ "datadog" ];
      };
      "logs/system" = {
        receivers = [ "journald" ];
        processors = [
          "transform/logs"
          "resourcedetection"
          "batch"
        ];
        exporters = [ "datadog" ];
      };
    };
  };

  # User configuration (removed root SSH keys - PermitRootLogin is "no" anyway)
  users.users.dan = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "kvm"
      "libvirtd"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHifaRXUcEaoTkf8dJF4qB7V9+VTjYX++fRbOKoCCpC2"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3DO7MvH49txkJjxZDZb4S3IWdeuEvN3UzPGbkvEtbE"
    ];
  };

  environment.systemPackages = with pkgs; [
    zellij
    nftables
    nodejs_24
    minio-client
  ];

  virtualisation = {
    libvirtd = {
      enable = true;
      allowedBridges = [ "virbr0" ];
    };
    docker = {
      enable = true;
    };
  };

  services = {
    # djv portfolio site
    djv = {
      enable = true;
      environment = "production";
      listenAddress = "127.0.0.1:7823";
      database.enable = true;
      sync = {
        enable = true;
        github.user = "djvcom";
        cratesIo.user = "djvcom";
        npm.user = "djverrall";
        gitlab.user = "djverrall";
      };
    };

    # Kanidm identity provider with passkey support
    kanidm = {
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
        systems.oauth2.openbao = {
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
      };
    };

    # Vaultwarden password manager (Bitwarden-compatible)
    vaultwarden = {
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

    # OpenBao secrets management (Vault fork)
    openbao = {
      enable = true;
      settings = {
        ui = true;
        api_addr = "https://bao.djv.sh";
        cluster_addr = "http://127.0.0.1:8201";

        # Listen on localhost only, Traefik handles TLS
        listener.tcp = {
          type = "tcp";
          address = "127.0.0.1:8200";
          tls_disable = true;
        };

        # Raft storage for single-node deployment
        storage.raft = {
          path = "/var/lib/openbao";
          node_id = "terminus";
        };
      };
    };

    # Stalwart all-in-one mail server (SMTP, IMAP, JMAP)
    stalwart-mail = {
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
        session.auth = {
          mechanisms = "[plain]";
          directory = "'memory'";
        };

        # Admin fallback account
        authentication.fallback-admin = {
          user = "admin";
          secret = "%{file:${config.age.secrets.stalwart-admin-password.path}}%";
        };
      };
    };

    # PostgreSQL with proper authentication
    postgresql = {
      enable = true;
      ensureDatabases = [
        "djv"
        "vaultwarden"
      ];
      ensureUsers = [
        {
          name = "dan";
          ensureClauses.superuser = true;
          ensureClauses.login = true;
        }
        {
          name = "djv";
          ensureDBOwnership = true;
        }
        {
          name = "vaultwarden";
          ensureDBOwnership = true;
        }
      ];
      settings = {
        password_encryption = "scram-sha-256";
      };
      authentication = lib.mkForce ''
        # Local connections use peer authentication (matches OS user)
        local all all peer
        # Network connections require password (scram-sha-256)
        host all all 127.0.0.1/32 scram-sha-256
        host all all ::1/128 scram-sha-256
      '';
    };

    minio = {
      enable = true;
      dataDir = [ "/var/lib/minio/data" ];
      rootCredentialsFile = config.age.secrets.minio-credentials.path;
      consoleAddress = "127.0.0.1:9001";
      listenAddress = "127.0.0.1:9000";
    };

    sslh = {
      listenAddresses = [ ];
      enable = true;
      settings = {
        listen = [
          {
            host = "0.0.0.0";
            port = "443";
            is_udp = false;
          }
        ];
        protocols = [
          {
            name = "ssh";
            host = "127.0.0.1";
            port = "22";
          }
          {
            name = "tls";
            host = "127.0.0.1";
            port = "8443";
            # Send PROXY protocol header so Traefik knows original client IP/port
            send_proxy = true;
          }
        ];
      };
    };

    nginx = {
      enable = false; # Replaced by Traefik
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedBrotliSettings = true;

      # Worker processes - use all available CPU cores
      appendConfig = ''
        worker_processes auto;
      '';

      # HTTP-level configuration
      appendHttpConfig = ''
        # Security headers (inherited by locations without their own add_header)
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

        # OCSP stapling for faster TLS handshakes
        ssl_stapling on;
        ssl_stapling_verify on;
        resolver 185.12.64.1 185.12.64.2 valid=300s;
        resolver_timeout 5s;

        # Fix proxy_headers_hash warning
        proxy_headers_hash_max_size 1024;
        proxy_headers_hash_bucket_size 128;
      '';

      # Virtual hosts configuration
      virtualHosts = {
        # Default server - reject requests with unknown Host header
        "_" = {
          default = true;
          listen = [
            {
              addr = "127.0.0.1";
              port = 8443;
              ssl = true;
            }
          ];
          useACMEHost = "djv.sh";
          addSSL = true;
          locations."/" = {
            return = "444";
          };
        };

        "djv.sh" = mkVhost {
          acmeHost = "djv.sh";
          proxyTo = "http://unix:/run/djv/djv.sock";
        };

        # stub_status for OpenTelemetry nginx receiver
        "stub_status" = {
          listen = [
            {
              addr = "127.0.0.1";
              port = 9145;
            }
          ];
          locations."/stub_status" = {
            extraConfig = ''
              stub_status;
              allow 127.0.0.1;
              deny all;
            '';
          };
          locations."/" = {
            return = "404";
          };
        };

        "state.djv.sh" = mkVhost {
          acmeHost = "state.djv.sh";
          proxyTo = "http://127.0.0.1:9000";
          extraLocationConfig = ''
            # MinIO specific
            proxy_buffering off;
            proxy_request_buffering off;
            client_max_body_size 0;
          '';
        };

        "minio.djv.sh" = mkVhost {
          acmeHost = "minio.djv.sh";
          proxyTo = "http://127.0.0.1:9001";
        };
      };
    };

    # Traefik reverse proxy (testing on port 8444, will replace nginx)
    traefik = {
      enable = true;

      environmentFiles = [ config.age.secrets.cloudflare-dns-token.path ];

      staticConfigOptions = {
        # Enable experimental OTLP logging
        experimental.otlpLogs = true;

        # Entry point for TLS traffic from sslh
        entryPoints.websecure = {
          address = "127.0.0.1:8443";
          # Accept PROXY protocol from sslh to get real client IP and port
          proxyProtocol.trustedIPs = [ "127.0.0.1/32" ];
          # Trust X-Forwarded-* headers from trusted sources
          forwardedHeaders.trustedIPs = [ "127.0.0.1/32" ];
        };

        # ACME certificate resolver using Cloudflare DNS-01
        certificatesResolvers.letsencrypt.acme = {
          email = "admin@djv.sh";
          storage = "/var/lib/traefik/acme.json";
          dnsChallenge = {
            provider = "cloudflare";
            # Use Hetzner DNS servers (external DNS blocked on this host)
            resolvers = [
              "185.12.64.1:53"
              "185.12.64.2:53"
            ];
          };
        };

        # OpenTelemetry tracing
        tracing = {
          otlp.http.endpoint = "http://127.0.0.1:4318/v1/traces";
          resourceAttributes = {
            "deployment.environment.name" = "production";
            "service.name" = "traefik";
          };
        };

        # OpenTelemetry metrics
        metrics.otlp.http.endpoint = "http://127.0.0.1:4318/v1/metrics";

        # Access logging - dual output for observability and Fail2ban
        accessLog = {
          # OTLP export for Datadog observability
          otlp.http.endpoint = "http://127.0.0.1:4318/v1/logs";
          # File output for Fail2ban parsing
          filePath = "/var/log/traefik/access.log";
          format = "common";
        };
      };

      dynamicConfigOptions = {
        http = {
          # Security headers middleware
          middlewares.security-headers.headers = {
            stsSeconds = 31536000;
            stsIncludeSubdomains = true;
            frameDeny = true;
            contentTypeNosniff = true;
            referrerPolicy = "strict-origin-when-cross-origin";
            customResponseHeaders = {
              Permissions-Policy = "geolocation=(), microphone=(), camera=()";
            };
          };

          # Routers for each domain
          routers = {
            djv = {
              rule = "Host(`${domains.djv.host}`)";
              service = "djv";
              middlewares = [ "security-headers" ];
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
            };

            minio-api = {
              rule = "Host(`${domains.minioApi.host}`)";
              service = "minio-api";
              middlewares = [ "security-headers" ];
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
            };

            minio-console = {
              rule = "Host(`${domains.minioConsole.host}`)";
              service = "minio-console";
              middlewares = [ "security-headers" ];
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
            };

            kanidm = {
              rule = "Host(`${domains.kanidm.host}`)";
              service = "kanidm";
              middlewares = [ "security-headers" ];
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
            };

            vaultwarden = {
              rule = "Host(`${domains.vaultwarden.host}`)";
              service = "vaultwarden";
              middlewares = [ "security-headers" ];
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
            };

            openbao = {
              rule = "Host(`${domains.openbao.host}`)";
              service = "openbao";
              middlewares = [ "security-headers" ];
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
            };

            stalwart = {
              rule = "Host(`${domains.stalwart.host}`)";
              service = "stalwart";
              middlewares = [ "security-headers" ];
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
            };

            # Catch-all router for unknown hosts (lowest priority)
            catch-all = {
              rule = "HostRegexp(`.*`)";
              priority = 1;
              service = "noop@internal";
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
            };
          };

          # Backend services
          services = {
            djv.loadBalancer.servers = [ { url = domains.djv.backend; } ];

            minio-api.loadBalancer = {
              servers = [ { url = domains.minioApi.backend; } ];
              passHostHeader = true;
              responseForwarding.flushInterval = "100ms";
            };

            minio-console.loadBalancer = {
              servers = [ { url = domains.minioConsole.backend; } ];
              passHostHeader = true;
            };

            # Kanidm handles TLS itself, so we need serversTransport
            kanidm.loadBalancer = {
              servers = [ { url = domains.kanidm.backend; } ];
              serversTransport = "kanidm-transport";
            };

            vaultwarden.loadBalancer.servers = [ { url = domains.vaultwarden.backend; } ];

            openbao.loadBalancer.servers = [ { url = domains.openbao.backend; } ];

            stalwart.loadBalancer.servers = [ { url = domains.stalwart.backend; } ];
          };

          # Server transport for Kanidm backend TLS
          serversTransports.kanidm-transport.insecureSkipVerify = true;
        };
      };
    };
  };

  # Create directories for services
  systemd.tmpfiles.rules = [
    "d /var/log/traefik 0750 traefik traefik -"
    "d /var/backup/kanidm 0750 kanidm kanidm -"
  ];

  # ACME certificates for services that handle their own TLS
  # (Traefik manages its own certs via certificatesResolvers)
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@djv.sh";
    certs = {
      # Kanidm terminates TLS itself, needs cert files
      "auth.djv.sh" = {
        dnsProvider = "cloudflare";
        environmentFile = config.age.secrets.cloudflare-dns-token.path;
        group = "kanidm";
      };
      # Stalwart mail server TLS
      "mail.djv.sh" = {
        dnsProvider = "cloudflare";
        environmentFile = config.age.secrets.cloudflare-dns-token.path;
        group = "stalwart-mail";
      };
    };
  };

  # Nix store optimisation
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "04:00";
    flake = "github:djvcom/nixos-config#terminus";
    flags = [
      "-L" # Show full build logs for better debugging
    ];
    rebootWindow = {
      lower = "04:00";
      upper = "05:00";
    };
    randomizedDelaySec = "5min";
  };

  # Upgrade monitoring - notify on failure via OTEL (only if observability enabled)
  systemd = {
    services = {
      nixos-upgrade = lib.mkIf config.modules.observability.enable {
        serviceConfig = {
          OnFailure = [ "nixos-upgrade-notify-failure.service" ];
        };
      };

      nixos-upgrade-notify-failure = lib.mkIf config.modules.observability.enable {
        description = "Notify on NixOS upgrade failure";
        serviceConfig.Type = "oneshot";
        path = [
          pkgs.curl
          pkgs.jq
        ];
        script = ''
          LOGS=$(journalctl -u nixos-upgrade.service -n 100 --no-pager | tail -50)
          ESCAPED_LOGS=$(echo "$LOGS" | jq -Rs .)

          # Send error log to OTEL collector
          curl -sf -X POST http://127.0.0.1:4318/v1/logs \
            -H "Content-Type: application/json" \
            -d "{
              \"resourceLogs\": [{
                \"resource\": {
                  \"attributes\": [
                    {\"key\": \"service.name\", \"value\": {\"stringValue\": \"nixos-upgrade\"}},
                    {\"key\": \"host.name\", \"value\": {\"stringValue\": \"terminus\"}}
                  ]
                },
                \"scopeLogs\": [{
                  \"logRecords\": [{
                    \"severityNumber\": 17,
                    \"severityText\": \"ERROR\",
                    \"body\": {\"stringValue\": \"NixOS auto-upgrade failed on terminus\"},
                    \"attributes\": [
                      {\"key\": \"upgrade.status\", \"value\": {\"stringValue\": \"failed\"}},
                      {\"key\": \"upgrade.logs\", \"value\": {\"stringValue\": $ESCAPED_LOGS}}
                    ]
                  }]
                }]
              }]
            }" || echo "Failed to send notification to OTEL"
        '';
      };

      # Pre-flight check - runs 30 min before upgrade to catch issues early
      nixos-upgrade-preflight = {
        description = "Pre-flight check for NixOS upgrade";
        unitConfig = lib.optionalAttrs config.modules.observability.enable {
          OnFailure = [ "nixos-upgrade-notify-failure.service" ];
        };
        serviceConfig.Type = "oneshot";
        path = [
          pkgs.nix
          pkgs.git
          pkgs.gnugrep
        ];
        script = ''
          set -euo pipefail
          echo "Starting NixOS upgrade pre-flight check..."

          # Force evaluation to catch warnings (eval always runs, unlike cached builds)
          echo "Evaluating flake..."
          nix eval github:djvcom/nixos-config#nixosConfigurations.terminus.config.system.build.toplevel.drvPath \
            --refresh \
            2>&1 | tee /var/tmp/nixos-preflight.log

          # Then build to ensure it actually works
          echo "Building configuration..."
          nix build github:djvcom/nixos-config#nixosConfigurations.terminus.config.system.build.toplevel \
            --no-link \
            -L 2>&1 | tee -a /var/tmp/nixos-preflight.log

          # Check for errors and echo them (so they appear in journal)
          if grep -qi "\berror\b\|\bfailed\b\|\bfailure\b" /var/tmp/nixos-preflight.log; then
            echo "Errors detected in build output:"
            grep -iE "\berror\b|\bfailed\b|\bfailure\b" /var/tmp/nixos-preflight.log | while read -r line; do
              echo "BUILD ERROR: $line"
            done
          fi

          # Check for deprecation warnings and echo them (so they appear in journal)
          if grep -qi "warning\|deprecated" /var/tmp/nixos-preflight.log; then
            echo "Warnings detected in build output:"
            grep -i "warning\|deprecated" /var/tmp/nixos-preflight.log | while read -r line; do
              echo "BUILD WARNING: $line"
            done
          fi

          echo "Pre-flight check completed successfully"
        '';
      };
    };

    timers.nixos-upgrade-preflight = {
      description = "Timer for NixOS upgrade pre-flight check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "03:30"; # 30 min before upgrade
        Persistent = true;
        RandomizedDelaySec = 60;
      };
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.dan =
      { ... }:
      {
        imports = [ ../../home/dan.nix ];
      };
  };

  system.stateVersion = "25.05";
}
