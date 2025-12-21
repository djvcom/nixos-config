{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/base.nix
    ../../modules/observability.nix
    ../../modules/wireguard.nix
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
    extraCommands = ''
      iptables -I nixos-fw 5 -p tcp -s 10.88.0.0/16 --dport 14317 -j nixos-fw-accept
      iptables -I nixos-fw 5 -p tcp -s 10.88.0.0/16 --dport 14318 -j nixos-fw-accept
    '';
    extraStopCommands = ''
      iptables -D nixos-fw -p tcp -s 10.88.0.0/16 --dport 14317 -j nixos-fw-accept 2>/dev/null || true
      iptables -D nixos-fw -p tcp -s 10.88.0.0/16 --dport 14318 -j nixos-fw-accept 2>/dev/null || true
    '';
  };

  modules.wireguard = {
    enable = true;
    address = "10.100.0.1/24";
    listenPort = 51820;
    peers = [];
  };

  age.secrets.datadog-api-key = {
    file = ../../secrets/datadog-api-key.age;
    owner = "root";
    group = "users";
    mode = "0440";
  };

  age.secrets.datadog-app-key = {
    file = ../../secrets/datadog-app-key.age;
    owner = "root";
    group = "users";
    mode = "0440";
  };

  age.secrets.minio-credentials = {
    file = ../../secrets/minio-credentials.age;
    owner = "minio";
    group = "minio";
    mode = "0400";
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

  age.secrets.git-identity = {
    file = ../../secrets/git-identity.age;
    path = "/home/dan/.config/git/identity";
    owner = "dan";
    group = "users";
    mode = "0440";
  };

  boot.kernelModules = [ "kvm-intel" "kvm-amd" "iptable_nat" "iptable_filter" ];
  boot.swraid.mdadmConf = "MAILADDR root";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGkRaEkD++/3Zkd2PsqmQtZ0t8CA16rQgyOs/J7zBj0D"
  ];

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

  services.postgresql = {
    enable = true;
    ensureUsers = [{
      name = "dan";
      ensureClauses.superuser = true;
      ensureClauses.login = true;
    }];
    authentication = lib.mkForce ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
  };

  services.minio = {
    enable = true;
    dataDir = [ "/var/lib/minio/data" ];
    rootCredentialsFile = config.age.secrets.minio-credentials.path;
    consoleAddress = "127.0.0.1:9001";
    listenAddress = "127.0.0.1:9000";
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
    virtualHosts."_" = {
      listen = [{ addr = "127.0.0.1"; port = 8443; ssl = true; }];
      onlySSL = true;
      sslCertificate = "/var/lib/nginx/selfsigned.crt";
      sslCertificateKey = "/var/lib/nginx/selfsigned.key";
      locations."/" = {
        return = "200 'terminus is running'";
        extraConfig = "add_header Content-Type text/plain;";
      };
    };
  };

  systemd.services.nginx-selfsigned-cert = {
    description = "Generate self-signed certificate for nginx";
    wantedBy = [ "nginx.service" ];
    before = [ "nginx.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -f /var/lib/nginx/selfsigned.crt ]; then
        mkdir -p /var/lib/nginx
        ${pkgs.openssl}/bin/openssl req -x509 -nodes -days 365 \
          -newkey rsa:2048 \
          -keyout /var/lib/nginx/selfsigned.key \
          -out /var/lib/nginx/selfsigned.crt \
          -subj "/CN=terminus"
        chown nginx:nginx /var/lib/nginx/selfsigned.*
        chmod 600 /var/lib/nginx/selfsigned.key
      fi
    '';
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
