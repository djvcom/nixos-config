{ config, lib, pkgs, ... }:

let
  # Helper for ACME certs - all use same Cloudflare DNS-01 config
  acmeDomains = [ "djv.sh" "state.djv.sh" "minio.djv.sh" ];
  mkAcmeCert = domain: {
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets.cloudflare-dns-token.path;
    group = "nginx";
  };

  # Common security headers to include in all locations with add_header
  securityHeaders = ''
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
  '';

  # Helper for nginx virtual hosts
  mkVhost = { acmeHost, proxyTo ? null, extraLocationConfig ? "" }: {
    listen = [{ addr = "127.0.0.1"; port = 8443; ssl = true; }];
    useACMEHost = acmeHost;
    addSSL = true;
    locations."/" = if proxyTo != null then {
      proxyPass = proxyTo;
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        ${extraLocationConfig}
      '';
    } else {
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

  networking.hostName = "terminus";

  networking.useDHCP = false;
  networking.interfaces.eth0 = {
    ipv4.addresses = [{
      address = "88.99.1.188";
      prefixLength = 24;
    }];
    ipv6.addresses = [{
      address = "2a01:4f8:173:28ab::2";
      prefixLength = 64;
    }];
  };
  networking.nameservers = [ "185.12.64.1" "185.12.64.2" ];
  networking.defaultGateway = "88.99.1.129";
  networking.defaultGateway6 = { address = "fe80::1"; interface = "eth0"; };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 443 ];
    allowPing = true;
    logRefusedConnections = true;
    # Allow OTEL ports only from Podman network
    extraCommands = ''
      iptables -I nixos-fw 5 -p tcp -s 10.88.0.0/16 --dport 4317 -j nixos-fw-accept
      iptables -I nixos-fw 5 -p tcp -s 10.88.0.0/16 --dport 4318 -j nixos-fw-accept
    '';
    extraStopCommands = ''
      iptables -D nixos-fw -p tcp -s 10.88.0.0/16 --dport 4317 -j nixos-fw-accept 2>/dev/null || true
      iptables -D nixos-fw -p tcp -s 10.88.0.0/16 --dport 4318 -j nixos-fw-accept 2>/dev/null || true
    '';
  };

  # Kernel and network hardening - see SECURITY.md for CIS/NIST references
  boot.kernelModules = [ "kvm-intel" "kvm-amd" "iptable_nat" "iptable_filter" ];
  boot.swraid.mdadmConf = "MAILADDR root";
  boot.kernel.sysctl = {
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

  # Secrets - with proper permissions
  age.secrets.datadog-api-key = {
    file = ../../secrets/datadog-api-key.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  age.secrets.datadog-app-key = {
    file = ../../secrets/datadog-app-key.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  age.secrets.minio-credentials = {
    file = ../../secrets/minio-credentials.age;
    owner = "minio";
    group = "minio";
    mode = "0400";
  };

  age.secrets.cloudflare-dns-token = {
    file = ../../secrets/cloudflare-dns-token.age;
    owner = "acme";
    group = "acme";
    mode = "0400";
  };

  age.secrets.git-identity = {
    file = ../../secrets/git-identity.age;
    path = "/home/dan/.config/git/identity";
    owner = "dan";
    group = "users";
    mode = "0440";
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
        receivers = [ "otlp" "hostmetrics" ];
        processors = [ "resourcedetection" "batch" ];
        exporters = [ "datadog" ];
      };
      traces = {
        receivers = [ "otlp" ];
        processors = [ "resourcedetection" "batch" ];
        exporters = [ "datadog" ];
      };
      logs = {
        receivers = [ "otlp" ];
        processors = [ "resourcedetection" "batch" ];
        exporters = [ "datadog" ];
      };
      "logs/system" = {
        receivers = [ "journald" ];
        processors = [ "transform/logs" "resourcedetection" "batch" ];
        exporters = [ "datadog" ];
      };
    };
  };

  # User configuration (removed root SSH keys - PermitRootLogin is "no" anyway)
  users.users.dan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "kvm" "libvirtd" "podman" ];
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

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.allowedBridges = [ "virbr0" ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # PostgreSQL with proper authentication
  services.postgresql = {
    enable = true;
    ensureUsers = [{
      name = "dan";
      ensureClauses.superuser = true;
      ensureClauses.login = true;
    }];
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

  services.minio = {
    enable = true;
    dataDir = [ "/var/lib/minio/data" ];
    rootCredentialsFile = config.age.secrets.minio-credentials.path;
    consoleAddress = "127.0.0.1:9001";
    listenAddress = "127.0.0.1:9000";
  };

  # ACME certificates - deduplicated with helper
  security.acme = {
    acceptTerms = true;
    defaults.email = "djverrall@gmail.com";
    certs = lib.genAttrs acmeDomains mkAcmeCert;
  };

  services.sslh = {
    listenAddresses = [];
    enable = true;
    settings = {
      listen = [{ host = "0.0.0.0"; port = "443"; is_udp = false; }];
      protocols = [
        { name = "ssh"; host = "127.0.0.1"; port = "22"; }
        { name = "tls"; host = "127.0.0.1"; port = "8443"; }
      ];
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Security headers at http level for locations without their own add_header
    appendHttpConfig = ''
      add_header X-Frame-Options "SAMEORIGIN" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header X-XSS-Protection "1; mode=block" always;
      add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    '';

    virtualHosts."djv.sh" = mkVhost { acmeHost = "djv.sh"; };

    virtualHosts."state.djv.sh" = mkVhost {
      acmeHost = "state.djv.sh";
      proxyTo = "http://127.0.0.1:9000";
      extraLocationConfig = ''
        # MinIO specific
        proxy_buffering off;
        proxy_request_buffering off;
        client_max_body_size 0;
      '';
    };

    virtualHosts."minio.djv.sh" = mkVhost {
      acmeHost = "minio.djv.sh";
      proxyTo = "http://127.0.0.1:9001";
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
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.dan = { ... }: {
      imports = [ ../../home/dan.nix ];
    };
  };

  system.stateVersion = "25.05";
}
