# Traefik reverse proxy with sslh protocol multiplexing
{ config, ... }:

let
  # Domain configuration for routing
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
in
{
  services = {
    # sslh multiplexes SSH and TLS on port 443
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
          # Kanidm uses ACME cert for auth.djv.sh but listens on 127.0.0.1
          # serverName tells Traefik which hostname to verify in the certificate
          serversTransports.kanidm-transport.serverName = "auth.djv.sh";
        };
      };
    };
  };

  # Create Traefik log directory
  systemd.tmpfiles.rules = [
    "d /var/log/traefik 0750 traefik traefik -"
  ];
}
