/**
  WireGuard VPN module with agenix-managed private keys.

  Configures a WireGuard interface (wg0) with:
  - Automatic firewall port opening
  - Secure key management via agenix
  - Flexible peer configuration

  References:
  - WireGuard: <https://www.wireguard.com/>
  - Key generation: {command}`wg genkey` and {command}`wg pubkey`
*/
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.wireguard;
in
{
  options.modules.wireguard = {
    enable = lib.mkEnableOption "WireGuard VPN";

    address = lib.mkOption {
      type = lib.types.str;
      description = "WireGuard interface IP address with CIDR notation";
      example = "10.100.0.1/24";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 51820;
      description = "UDP port for WireGuard to listen on";
    };

    privateKeySecret = lib.mkOption {
      type = lib.types.str;
      default = "../secrets/wireguard-private.age";
      description = "Path to agenix secret file containing the private key (relative to importing module)";
      example = "../../secrets/wireguard-private.age";
    };

    peers = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            publicKey = lib.mkOption {
              type = lib.types.str;
              description = "Base64-encoded public key generated with {command}`wg pubkey`";
            };
            allowedIPs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "IP ranges this peer is allowed to use as source";
              example = lib.literalExpression ''[ "10.100.0.2/32" ]'';
            };
            endpoint = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Peer endpoint in host:port format (optional for clients behind NAT)";
              example = "vpn.example.com:51820";
            };
            persistentKeepalive = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "Keepalive interval in seconds (useful for NAT traversal)";
              example = 25;
            };
          };
        }
      );
      default = [ ];
      description = "List of WireGuard peers";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ cfg.listenPort ];

    age.secrets.wireguard-private = {
      file = cfg.privateKeySecret;
      owner = "root";
      group = "root";
      mode = "0600";
    };

    environment.systemPackages = [ pkgs.wireguard-tools ];

    networking.wireguard.interfaces.wg0 = {
      ips = [ cfg.address ];
      inherit (cfg) listenPort;
      privateKeyFile = config.age.secrets.wireguard-private.path;
      peers = map (
        peer:
        {
          inherit (peer) publicKey allowedIPs;
        }
        // lib.optionalAttrs (peer.endpoint != null) {
          inherit (peer) endpoint;
        }
        // lib.optionalAttrs (peer.persistentKeepalive != null) {
          inherit (peer) persistentKeepalive;
        }
      ) cfg.peers;
    };
  };
}
