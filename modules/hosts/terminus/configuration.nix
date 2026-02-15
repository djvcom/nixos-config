# Terminus server - feature selection and host-specific config
{ inputs, ... }:

{
  flake.modules.nixos.terminus =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        # Tools
        agenix
        home-manager

        # Base
        boot
        security
        ssh
        nix-settings
        base-packages

        # Server
        hardening
        postgresql
        traefik
        acme
        virtualisation

        # Observability
        observability
        datadog

        # Backup
        backup

        # Services
        djv
        kanidm
        vaultwarden
        stalwart
        garage
        openbao
        valkey
        roundcube
        dashboard
        sidereal
      ];

      networking = {
        hostName = "terminus";
        useDHCP = false;
        # Resolve mail.djv.sh to localhost for Roundcube IMAP connection
        hosts."127.0.0.1" = [ "mail.djv.sh" ];
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

      # User and group configuration
      users = {
        # Shared group for services needing mail credentials
        groups.mail-secrets = { };

        users.dan = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "networkmanager"
            "kvm"
            "libvirtd"
            "docker"
          ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKGGvADTZrv8lir6I2mTEtef/r1StZ0pfAkRNZcr9tE dan@macbook-personal"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3DO7MvH49txkJjxZDZb4S3IWdeuEvN3UzPGbkvEtbE dan@macbook-work"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbuNAs2R2clu+9Xd37pWsQblShESDYejJAGfgCxSKG/ dan@oshun"
          ];
        };
      };

      environment.systemPackages = with pkgs; [
        zellij
        nftables
        nodejs_24
      ];

      # Host-specific PostgreSQL databases and users
      services.postgresql = {
        ensureDatabases = [
          "djv"
          "vaultwarden"
          "roundcube"
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
          # Datadog monitoring user
          {
            name = "datadog";
            ensureClauses.login = true;
          }
        ];
      };

      # Nix store optimisation
      nix.optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };

      home-manager.users.dan =
        { ... }:
        {
          imports = with inputs.self.modules.homeManager; [
            base
            shell
            git
            neovim
            gitlab
          ];
          home.username = "dan";
          home.homeDirectory = "/home/dan";
        };

      system.stateVersion = "25.05";
    };
}
