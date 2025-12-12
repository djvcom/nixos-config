{ config, lib, pkgs, ... }:

let
  hostConfig = import ./hosts/terminus.nix;
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  age.secrets = {
    git-identity = {
      file = ./secrets/git-identity.age;
      path = "/home/dan/.config/git/identity";
      owner = "dan";
      group = "users";
      mode = "0600";
    };
    wireguard-private = {
      file = ./secrets/wireguard-private.age;
      owner = "root";
      group = "root";
      mode = "0600";
    };
  };

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
      address = hostConfig.networking.ipv4Address;
      prefixLength = hostConfig.networking.ipv4PrefixLength;
    }];
    ipv6.addresses = [{
      address = hostConfig.networking.ipv6Address;
      prefixLength = hostConfig.networking.ipv6PrefixLength;
    }];
  };
  networking.nameservers = hostConfig.networking.nameservers;
  networking.defaultGateway = hostConfig.networking.ipv4Gateway;
  networking.defaultGateway6 = { address = "fe80::1"; interface = "eth0"; };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ 51820 ];
    allowPing = true;
  };

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.1/24" ];
    listenPort = 51820;
    privateKeyFile = config.age.secrets.wireguard-private.path;
    peers = [];
  };

  security.sudo.extraRules = [{
    users = [ "dan" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
  security.protectKernelImage = true;

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGkRaEkD++/3Zkd2PsqmQtZ0t8CA16rQgyOs/J7zBj0D"
  ];
  users.users.dan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "kvm" "libvirtd" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHifaRXUcEaoTkf8dJF4qB7V9+VTjYX++fRbOKoCCpC2"
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    zellij
    nodejs_24
    age
    wireguard-tools
  ];

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.allowedBridges = [ "virbr0" ];

  programs.nix-ld.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
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
      imports = [ ./home.nix ];
    };
  };

  system.stateVersion = "25.05";
}
