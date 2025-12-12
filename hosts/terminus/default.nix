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
    allowedTCPPorts = [ 22 ];
    allowPing = true;
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
    group = "root";
    mode = "0600";
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
        receivers = [ "otlp" "journald" ];
        processors = [ "resourcedetection" "batch" ];
        exporters = [ "datadog" ];
      };
    };
  };

  age.secrets.git-identity = {
    file = ../../secrets/git-identity.age;
    path = "/home/dan/.config/git/identity";
    owner = "dan";
    group = "users";
    mode = "0600";
  };

  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  boot.swraid.mdadmConf = "MAILADDR root";

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
    zellij
    nodejs_24
  ];

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.allowedBridges = [ "virbr0" ];

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
