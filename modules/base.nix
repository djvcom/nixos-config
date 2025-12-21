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
  services = {
    fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      bantime-increment.enable = true;
      jails = {
        # Protect against HTTP authentication brute-force
        nginx-http-auth.settings = {
          enabled = true;
          filter = "nginx-http-auth";
          maxretry = 5;
        };
        # Protect against bots scanning for vulnerabilities
        nginx-botsearch.settings = {
          enabled = true;
          filter = "nginx-botsearch";
          maxretry = 5;
        };
        # Protect against excessive 4xx errors (scanners, bad bots)
        nginx-bad-request.settings = {
          enabled = true;
          filter = "nginx-bad-request";
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
