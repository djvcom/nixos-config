{ config, lib, pkgs, ... }:

let
  cfg = config.modules.wireguard;
in
{
  options.modules.wireguard = {
    enable = lib.mkEnableOption "Wireguard VPN";

    address = lib.mkOption {
      type = lib.types.str;
      description = "Wireguard interface IP address with CIDR";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 51820;
      description = "UDP port for Wireguard";
    };

    peers = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "List of Wireguard peers";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ cfg.listenPort ];

    age.secrets.wireguard-private = {
      file = ../secrets/wireguard-private.age;
      owner = "root";
      group = "root";
      mode = "0600";
    };

    environment.systemPackages = [ pkgs.wireguard-tools ];

    networking.wireguard.interfaces.wg0 = {
      ips = [ cfg.address ];
      listenPort = cfg.listenPort;
      privateKeyFile = config.age.secrets.wireguard-private.path;
      peers = cfg.peers;
    };
  };
}
