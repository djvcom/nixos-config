{ config, lib, pkgs, ... }:

let
  secrets = import ./secrets.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  boot.tmp.cleanOnBoot = true;
  boot.loader.systemd-boot.editor = false;
  boot.swraid.mdadmConf = "MAILADDR root";

  networking.hostName = "terminus";
  networking.useDHCP = false;
  networking.interfaces.eth0 = {
    ipv4.addresses = [{
      address = secrets.networking.ipv4Address;
      prefixLength = secrets.networking.ipv4PrefixLength;
    }];
    ipv6.addresses = [{
      address = secrets.networking.ipv6Address;
      prefixLength = secrets.networking.ipv6PrefixLength;
    }];
  };
  networking.nameservers = secrets.networking.nameservers;
  networking.defaultGateway = secrets.networking.ipv4Gateway;
  networking.defaultGateway6 = { address = "fe80::1"; interface = "eth0"; };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowPing = true;
  };

  security.sudo.extraRules = [{
    users = [ "dan" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
  security.protectKernelImage = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "yes";
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [ secrets.sshKeys.root ];
  users.users.dan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "kvm" "libvirtd" ];
    openssh.authorizedKeys.keys = [ secrets.sshKeys.dan ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    zellij
    nodejs_24
  ];

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.allowedBridges = [ "virbr0" ];

  programs.nix-ld.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "04:00";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.dan = { config, pkgs, lib, ... }: {
      imports = [ (import ./home.nix { inherit secrets; }) ];
    };
  };

  system.stateVersion = "25.05";
}
