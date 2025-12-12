# NixOS Configuration

NixOS configuration for personal development and hosting infrastructure.

## Structure

```
├── flake.nix              # Entry point
├── flake.lock             # Pinned dependencies
├── configuration.nix      # System configuration
├── home.nix               # User environment (home-manager)
├── hardware-configuration.nix  # Hardware-specific settings
├── hosts/
│   └── terminus.nix       # Host-specific networking
└── secrets/
    ├── secrets.nix        # Defines who can decrypt
    └── *.age              # Encrypted secrets (agenix)
```

## Setup

1. Clone this repository to `/etc/nixos`
2. Copy `hosts/terminus.nix.example` to `hosts/terminus.nix` and fill in your networking details
3. Run `sudo nixos-rebuild switch --flake .#terminus`

## Secrets Management

Secrets are encrypted using [agenix](https://github.com/ryantm/agenix) with age.
To edit secrets, you need access to either:
- The machine's SSH host key
- A user SSH key listed in `secrets/secrets.nix`

## Hosts

| Name | Purpose | Wireguard IP |
|------|---------|--------------|
| terminus | Primary development and hosting server | 10.100.0.1 |

## Wireguard VPN

The infrastructure uses Wireguard for private encrypted communication between hosts.

### Network Details

- **Subnet**: 10.100.0.0/24
- **Hub**: terminus (10.100.0.1)
- **Port**: UDP 51820

### Adding a New Peer

#### 1. Generate keys on the new device

```bash
wg genkey | tee privatekey | wg pubkey > publickey
```

#### 2. Add the peer to terminus

Edit `configuration.nix` and add to `networking.wireguard.interfaces.wg0.peers`:

```nix
{
  publicKey = "<new-device-public-key>";
  allowedIPs = [ "10.100.0.X/32" ];
}
```

Rebuild: `sudo nixos-rebuild switch --flake /etc/nixos#terminus`

#### 3. Configure the new device

Create a config file (e.g., `/etc/wireguard/wg0.conf`):

```ini
[Interface]
PrivateKey = <new-device-private-key>
Address = 10.100.0.X/24

[Peer]
PublicKey = NsJCELWk3QQ+331ZlsZZGDnA5J30yGpAbatORFHrWzs=
Endpoint = 88.99.1.188:51820
AllowedIPs = 10.100.0.0/24
PersistentKeepalive = 25
```

#### 4. Connect

```bash
sudo wg-quick up wg0
```

### IP Allocation

| IP | Device |
|----|--------|
| 10.100.0.1 | terminus |
| 10.100.0.2-254 | Available for new peers |
