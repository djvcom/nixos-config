# WireGuard VPN module with agenix-managed private keys
_:

{
  flake.modules.nixos.wireguard =
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
          description = "Path to agenix secret file containing the private key";
        };

        peers = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                publicKey = lib.mkOption {
                  type = lib.types.str;
                  description = "Base64-encoded public key";
                };
                allowedIPs = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "IP ranges this peer is allowed to use";
                };
                endpoint = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Peer endpoint in host:port format";
                };
                persistentKeepalive = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  default = null;
                  description = "Keepalive interval in seconds";
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
    };
}
