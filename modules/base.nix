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
  # Host-specific jails (e.g. Traefik) are defined in their respective modules
  services = {
    fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      bantime-increment.enable = true;
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

  # Required by home-manager when useUserPackages = true
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

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
