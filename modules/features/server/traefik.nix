# Traefik reverse proxy with sslh protocol multiplexing
_:

{
  flake.modules.nixos.traefik =
    { config, ... }:
    let
      domains = {
        djv = {
          host = "djv.sh";
          backend = "http://127.0.0.1:7823";
        };
        garage = {
          host = "s3.djv.sh";
          s3Backend = "http://127.0.0.1:3900";
        };
        garageAdmin = {
          host = "garage.djv.sh";
          backend = "http://127.0.0.1:4180";
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
        roundcube = {
          host = "webmail.djv.sh";
          backend = "http://127.0.0.1:4182";
        };
        dashboard = {
          host = "dash.djv.sh";
          backend = "http://127.0.0.1:4181";
        };
      };
    in
    {
      services = {
        # Fail2ban jails for Traefik access log
        # Traefik logs in common format to /var/log/traefik/access.log
        fail2ban.jails = {
          # Protect against HTTP authentication failures (401/403)
          traefik-auth.settings = {
            enabled = true;
            filter = "traefik-auth";
            logpath = "/var/log/traefik/access.log";
            backend = "auto";
            maxretry = 5;
          };
          # Protect against bots scanning for vulnerabilities (repeated 404s)
          traefik-botsearch.settings = {
            enabled = true;
            filter = "traefik-botsearch";
            logpath = "/var/log/traefik/access.log";
            backend = "auto";
            maxretry = 10;
          };
          # Protect against bad requests (400 errors)
          traefik-badrequest.settings = {
            enabled = true;
            filter = "traefik-badrequest";
            logpath = "/var/log/traefik/access.log";
            backend = "auto";
            maxretry = 10;
          };
        };

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

          dynamic.dir = "/var/lib/traefik/dynamic";
          environmentFiles = [ config.age.secrets.cloudflare-dns-token.path ];

          static.settings = {
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

          dynamic.files.routing.settings = {
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

                # Security headers for Roundcube (allows same-origin framing for email preview)
                security-headers-roundcube.headers = {
                  stsSeconds = 31536000;
                  stsIncludeSubdomains = true;
                  customFrameOptionsValue = "SAMEORIGIN";
                  contentTypeNosniff = true;
                  referrerPolicy = "strict-origin-when-cross-origin";
                  customResponseHeaders = {
                    Permissions-Policy = "geolocation=(), microphone=(), camera=()";
                  };
                };

                # Rate limiting for general traffic (100 req/s average, burst of 50)
                rate-limit.rateLimit = {
                  average = 100;
                  burst = 50;
                };

                # Stricter rate limiting for authentication endpoints
                auth-rate-limit.rateLimit = {
                  average = 10;
                  burst = 20;
                };
              };

              routers = {
                djv = {
                  rule = "Host(`${domains.djv.host}`)";
                  service = "djv";
                  middlewares = [ "security-headers" ];
                  tls.certResolver = "letsencrypt";
                  entryPoints = [ "websecure" ];
                };

                # Garage S3 API (access key auth)
                garage-s3 = {
                  rule = "Host(`${domains.garage.host}`)";
                  service = "garage-s3";
                  middlewares = [ "security-headers" ];
                  tls.certResolver = "letsencrypt";
                  entryPoints = [ "websecure" ];
                };

                # Garage Admin UI (SSO via oauth2-proxy)
                garage-admin = {
                  rule = "Host(`${domains.garageAdmin.host}`)";
                  service = "garage-admin";
                  middlewares = [
                    "rate-limit"
                    "security-headers"
                  ];
                  tls.certResolver = "letsencrypt";
                  entryPoints = [ "websecure" ];
                };

                kanidm = {
                  rule = "Host(`${domains.kanidm.host}`)";
                  service = "kanidm";
                  middlewares = [
                    "auth-rate-limit"
                    "security-headers"
                  ];
                  tls.certResolver = "letsencrypt";
                  entryPoints = [ "websecure" ];
                };

                vaultwarden = {
                  rule = "Host(`${domains.vaultwarden.host}`)";
                  service = "vaultwarden";
                  middlewares = [
                    "rate-limit"
                    "security-headers"
                  ];
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

                roundcube = {
                  rule = "Host(`${domains.roundcube.host}`)";
                  service = "roundcube";
                  middlewares = [ "security-headers-roundcube" ];
                  tls.certResolver = "letsencrypt";
                  entryPoints = [ "websecure" ];
                };

                dashboard = {
                  rule = "Host(`${domains.dashboard.host}`)";
                  service = "dashboard";
                  middlewares = [
                    "rate-limit"
                    "security-headers"
                  ];
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

              services = {
                djv.loadBalancer.servers = [ { url = domains.djv.backend; } ];

                garage-s3.loadBalancer = {
                  servers = [ { url = domains.garage.s3Backend; } ];
                  passHostHeader = true;
                  responseForwarding.flushInterval = "100ms";
                };

                garage-admin.loadBalancer.servers = [ { url = domains.garageAdmin.backend; } ];

                # Kanidm handles TLS itself, so we need serversTransport
                kanidm.loadBalancer = {
                  servers = [ { url = domains.kanidm.backend; } ];
                  serversTransport = "kanidm-transport";
                };

                vaultwarden.loadBalancer.servers = [ { url = domains.vaultwarden.backend; } ];

                openbao.loadBalancer.servers = [ { url = domains.openbao.backend; } ];

                stalwart.loadBalancer.servers = [ { url = domains.stalwart.backend; } ];

                roundcube.loadBalancer.servers = [ { url = domains.roundcube.backend; } ];

                dashboard.loadBalancer.servers = [ { url = domains.dashboard.backend; } ];
              };

              # Server transport for Kanidm backend TLS
              # Kanidm uses ACME cert for auth.djv.sh but listens on 127.0.0.1
              # serverName tells Traefik which hostname to verify in the certificate
              serversTransports.kanidm-transport.serverName = "auth.djv.sh";
            };
          };
        };
      };

      # Custom fail2ban filters for Traefik (common log format)
      # See: https://nixos.wiki/wiki/Fail2ban
      environment.etc = {
        "fail2ban/filter.d/traefik-auth.conf".text = ''
          [Definition]
          failregex = ^<HOST> - - \[.*\] ".*" (401|403) .*$
          ignoreregex =
        '';
        "fail2ban/filter.d/traefik-botsearch.conf".text = ''
          [Definition]
          failregex = ^<HOST> - - \[.*\] ".*" 404 .*$
          ignoreregex = \.(css|js|png|jpg|jpeg|gif|ico|woff|woff2|svg)
        '';
        "fail2ban/filter.d/traefik-badrequest.conf".text = ''
          [Definition]
          failregex = ^<HOST> - - \[.*\] ".*" 400 .*$
          ignoreregex =
        '';
      };

      systemd.tmpfiles.rules = [
        "d /var/log/traefik 0750 traefik traefik -"
      ];
    };
}
