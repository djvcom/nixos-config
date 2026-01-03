/**
  Base system configuration shared across all hosts.

  Configures:
  - systemd-boot with secure defaults
  - SSH hardening (key-only auth, no root login)
  - Fail2ban brute-force protection
  - Automatic garbage collection

  References:
  - SSH: <https://nvlpubs.nist.gov/nistpubs/ir/2015/NIST.IR.7966.pdf>
  - CIS Benchmarks: <https://www.cisecurity.org/cis-benchmarks>
*/
{ pkgs, ... }:

{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };
    tmp.cleanOnBoot = true;
  };

  security = {
    # NOPASSWD accepted for single-user personal infrastructure:
    # - SSH uses key-only auth (password disabled)
    # - Server not shared with other users
    # - Attacker with SSH access already has user context
    sudo.extraRules = [
      {
        users = [ "dan" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    protectKernelImage = true;
  };

  # Brute-force protection - see <https://www.fail2ban.org/>
  # Traefik logs in common format to /var/log/traefik/access.log
  services = {
    fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      bantime-increment.enable = true;
      jails = {
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
    };

    # SSH hardening per NIST IR 7966 and CIS benchmarks
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    age
    gnumake
    just
  ];

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

  programs.nix-ld.enable = true;

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
