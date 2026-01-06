# Traefik reverse proxy with sslh protocol multiplexing
{ config, ... }:

let
  # Domain configuration for routing
  domains = {
    djv = {
      host = "djv.sh";
      backend = "http://127.0.0.1:7823";
    };
    garage = {
      host = "s3.djv.sh";
      s3Backend = "http://127.0.0.1:3900";
      uiBackend = "http://127.0.0.1:4180"; # oauth2-proxy
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
          middlewares = {
            # Redirect unknown subdomains to main site 404
            redirect-to-404.redirectRegex = {
              regex = ".*";
              replacement = "https://djv.sh/404";
              permanent = false;
            };

            # Security headers middleware
            security-headers.headers = {
              stsSeconds = 31536000;
              stsIncludeSubdomains = true;
              frameDeny = true;
              contentTypeNosniff = true;
              referrerPolicy = "strict-origin-when-cross-origin";
              customResponseHeaders = {
                Permissions-Policy = "geolocation=(), microphone=(), camera=()";
              };
            };

            # Strip /ui prefix for garage-webui
            garage-strip-ui.stripPrefix.prefixes = [ "/ui" ];
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

            # Garage UI (SSO via oauth2-proxy) - strip /ui prefix for webui
            garage-ui = {
              rule = "Host(`${domains.garage.host}`) && PathPrefix(`/ui`)";
              service = "garage-ui";
              middlewares = [
                "garage-strip-ui"
                "security-headers"
              ];
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
              priority = 10;
            };

            # Garage OAuth2 callbacks - don't strip prefix
            garage-oauth2 = {
              rule = "Host(`${domains.garage.host}`) && PathPrefix(`/oauth2`)";
              service = "garage-ui";
              middlewares = [ "security-headers" ];
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
              priority = 10;
            };

            # Garage webui static assets and API (direct to webui)
            garage-assets = {
              rule = "Host(`${domains.garage.host}`) && (PathPrefix(`/assets`) || PathPrefix(`/api`) || Path(`/favicon-16x16.png`) || Path(`/favicon-32x32.png`) || Path(`/apple-touch-icon.png`) || Path(`/site.webmanifest`))";
              service = "garage-webui-direct";
              middlewares = [ "security-headers" ];
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
              priority = 10;
            };

            # Garage S3 API (access key auth) - lower priority than UI routes
            garage-s3 = {
              rule = "Host(`${domains.garage.host}`)";
              service = "garage-s3";
              middlewares = [ "security-headers" ];
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
              priority = 1;
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

            # Catch-all for unknown subdomains - redirect to main site 404 page
            catch-all = {
              rule = "HostRegexp(`^.+\\.djv\\.sh$`)";
              service = "djv"; # Redirect happens before reaching backend
              middlewares = [ "redirect-to-404" ];
              entryPoints = [ "websecure" ];
              priority = 1;
              tls = {
                certResolver = "letsencrypt";
                domains = [
                  {
                    main = "djv.sh";
                    sans = [ "*.djv.sh" ];
                  }
                ];
              };
            };

          };

          # Backend services
          services = {
            djv.loadBalancer.servers = [ { url = domains.djv.backend; } ];

            garage-s3.loadBalancer = {
              servers = [ { url = domains.garage.s3Backend; } ];
              passHostHeader = true;
              responseForwarding.flushInterval = "100ms";
            };

            garage-ui.loadBalancer.servers = [ { url = domains.garage.uiBackend; } ];

            # Direct access to garage-webui for static assets (bypasses oauth2-proxy)
            garage-webui-direct.loadBalancer.servers = [ { url = "http://127.0.0.1:3902"; } ];

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
