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
        sidereal = {
          host = "sidereal.djv.sh";
          backend = "http://127.0.0.1:3100";
        };
      };
    in
    {
      services = {
        fail2ban.jails = {
          traefik-auth.settings = {
            enabled = true;
            filter = "traefik-auth";
            logpath = "/var/log/traefik/access.log";
            backend = "auto";
            maxretry = 5;
          };
          traefik-botsearch.settings = {
            enabled = true;
            filter = "traefik-botsearch";
            logpath = "/var/log/traefik/access.log";
            backend = "auto";
            maxretry = 10;
          };
          traefik-badrequest.settings = {
            enabled = true;
            filter = "traefik-badrequest";
            logpath = "/var/log/traefik/access.log";
            backend = "auto";
            maxretry = 10;
          };
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
                send_proxy = true;
              }
            ];
          };
        };

        traefik = {
          enable = true;

          environmentFiles = [ config.age.secrets.cloudflare-dns-token.path ];

          staticConfigOptions = {
            experimental.otlpLogs = true;

            entryPoints.websecure = {
              address = "127.0.0.1:8443";
              proxyProtocol.trustedIPs = [ "127.0.0.1/32" ];
              forwardedHeaders.trustedIPs = [ "127.0.0.1/32" ];
            };

            certificatesResolvers.letsencrypt.acme = {
              email = "admin@djv.sh";
              storage = "/var/lib/traefik/acme.json";
              dnsChallenge = {
                provider = "cloudflare";
                resolvers = [
                  "185.12.64.1:53"
                  "185.12.64.2:53"
                ];
              };
            };

            tracing = {
              otlp.http.endpoint = "http://127.0.0.1:4318/v1/traces";
              resourceAttributes = {
                "deployment.environment.name" = "production";
                "service.name" = "traefik";
              };
            };

            metrics.otlp.http.endpoint = "http://127.0.0.1:4318/v1/metrics";

            accessLog = {
              otlp.http.endpoint = "http://127.0.0.1:4318/v1/logs";
              filePath = "/var/log/traefik/access.log";
              format = "common";
            };
          };

          dynamicConfigOptions = {
            http = {
              middlewares = {
                redirect-to-404.redirectRegex = {
                  regex = ".*";
                  replacement = "https://djv.sh/404";
                  permanent = false;
                };

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

                rate-limit.rateLimit = {
                  average = 100;
                  burst = 50;
                };

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

                garage-s3 = {
                  rule = "Host(`${domains.garage.host}`)";
                  service = "garage-s3";
                  middlewares = [ "security-headers" ];
                  tls.certResolver = "letsencrypt";
                  entryPoints = [ "websecure" ];
                };

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

                sidereal = {
                  rule = "Host(`${domains.sidereal.host}`)";
                  service = "sidereal";
                  middlewares = [
                    "security-headers"
                    "rate-limit"
                  ];
                  tls.certResolver = "letsencrypt";
                  entryPoints = [ "websecure" ];
                };

                catch-all = {
                  rule = "HostRegexp(`^.+\\.djv\\.sh$`)";
                  service = "djv";
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

                kanidm.loadBalancer = {
                  servers = [ { url = domains.kanidm.backend; } ];
                  serversTransport = "kanidm-transport";
                };

                vaultwarden.loadBalancer.servers = [ { url = domains.vaultwarden.backend; } ];

                openbao.loadBalancer.servers = [ { url = domains.openbao.backend; } ];

                stalwart.loadBalancer.servers = [ { url = domains.stalwart.backend; } ];

                sidereal.loadBalancer.servers = [ { url = domains.sidereal.backend; } ];
              };

              serversTransports.kanidm-transport.serverName = "auth.djv.sh";
            };
          };
        };
      };

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
