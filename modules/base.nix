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
{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.cleanOnBoot = true;

  security.sudo.extraRules = [{
    users = [ "dan" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
  security.protectKernelImage = true;

  # Brute-force protection - see <https://www.fail2ban.org/>
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment.enable = true;
  };

  # SSH hardening per NIST IR 7966 and CIS benchmarks
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    age
  ];

  programs.nix-ld.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
