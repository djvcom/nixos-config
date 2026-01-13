# Nix Configuration

NixOS and nix-darwin configuration for personal development infrastructure.

## Structure

```
├── flake.nix                    # Entry point, defines all hosts
├── flake.lock                   # Pinned dependencies
├── hosts/
│   ├── terminus/                # NixOS server
│   │   ├── default.nix          # Host-specific configuration
│   │   ├── hardware.nix         # Hardware settings (nixos-generate-config)
│   │   └── disko.nix            # Disk partitioning (for nixos-anywhere)
│   ├── macbook/                 # Shared macOS base
│   │   └── base.nix             # Common darwin configuration
│   ├── macbook-personal/        # Personal MacBook
│   │   └── default.nix          # Imports base + personal apps (GOG, Jellyfin)
│   └── macbook-work/            # Work MacBook
│       └── default.nix          # Imports base, work-only config
├── modules/
│   ├── base.nix                 # Security, SSH, fail2ban, nix settings
│   ├── observability.nix        # OpenTelemetry metrics/traces/logs
│   └── wireguard.nix            # VPN configuration
├── home/
│   ├── generic.nix              # Shared home-manager config
│   └── dan/                     # User-specific modules
│       ├── shell.nix            # Bash/Zsh, aliases, starship, direnv
│       ├── git.nix              # Git config with delta
│       ├── neovim.nix           # Neovim with LSP, treesitter, catppuccin
│       ├── ghostty.nix          # Ghostty terminal config
│       ├── firefox.nix          # LibreWolf with extensions
│       ├── aerospace.nix        # Tiling window manager (macOS)
│       └── gitlab.nix           # GitLab token rotation
└── secrets/
    ├── secrets.nix              # Defines who can decrypt
    └── *.age                    # Encrypted secrets (agenix)
```

## Modules

| Module | Purpose | Options |
|--------|---------|---------|
| `base.nix` | Security baseline for all servers | Imported by all hosts |
| `observability.nix` | OTEL collector with configurable backend | `modules.observability.enable`, `exporters`, `pipelines` |
| `wireguard.nix` | VPN with configurable IP and peers | `modules.wireguard.enable`, `address`, `peers` |

## Adding a New Host

1. Create the host directory:
   ```bash
   mkdir -p hosts/newhost
   ```

2. Create `hosts/newhost/default.nix`:
   ```nix
   { config, pkgs, ... }:
   {
     imports = [
       ./hardware.nix
       ../../modules/base.nix
       # Add other modules as needed
     ];

     networking.hostName = "newhost";
     # Host-specific configuration...

     system.stateVersion = "25.05";
   }
   ```

3. Add to `flake.nix`:
   ```nix
   nixosConfigurations.newhost = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     modules = [
       ./hosts/newhost
       home-manager.nixosModules.home-manager
       agenix.nixosModules.default
       disko.nixosModules.disko
     ];
   };
   ```

4. Deploy with nixos-anywhere (new server) or nixos-rebuild (existing):
   ```bash
   # New server with disko partitioning
   nixos-anywhere --flake .#newhost root@<ip>

   # Existing server
   nixos-rebuild switch --flake .#newhost
   ```

## Secrets Management

Secrets are encrypted using [agenix](https://github.com/ryantm/agenix).

To edit a secret:
```bash
agenix -e secrets/secret-name.age
```

To add a new secret:
1. Add the secret definition to `secrets/secrets.nix`
2. Create the encrypted file: `agenix -e secrets/new-secret.age`
3. Reference in your host config via `age.secrets`

## Hosts

| Name | Platform | Purpose |
|------|----------|---------|
| terminus | NixOS | Primary development and hosting server |
| macbook-personal | macOS (nix-darwin) | Personal laptop with gaming apps |
| macbook-work | macOS (nix-darwin) | Work laptop, no personal apps |

## macOS Setup (nix-darwin)

### Initial Setup

1. Install Nix (official installer):
   ```bash
   sh <(curl -L https://nixos.org/nix/install)
   ```

2. Clone this repo:
   ```bash
   git clone <repo-url> ~/.config/nix-darwin
   ```

3. Bootstrap nix-darwin:
   ```bash
   nix --extra-experimental-features "nix-command flakes" run nix-darwin -- \
     switch --flake ~/.config/nix-darwin#macbook-personal --impure
   ```

4. Set up git identity (not tracked):
   ```bash
   mkdir -p ~/.config/git
   cat > ~/.config/git/identity << 'EOF'
   [user]
       name = Your Name
       email = your@email.com
   EOF
   ```

5. Set up GitLab CLI:
   ```bash
   glab auth login
   ```

### Daily Usage

Rebuild after config changes:
```bash
rebuild
```

The `rebuild` alias automatically targets the correct flake configuration based on which machine you're on.

### What's Included (macOS)

**System:**
- Homebrew managed declaratively (Ghostty, GOG Galaxy on personal)
- Touch ID for sudo
- Passwordless `darwin-rebuild`

**Terminal:**
- Ghostty with Catppuccin Mocha theme, 90% opacity
- Zsh with autosuggestions, syntax highlighting
- Starship prompt
- Modern CLI tools: eza, bat, delta, fzf, ripgrep, fd, bottom, dust, procs

**Development:**
- Neovim with LSP (Rust, TypeScript, Nix), treesitter, telescope
- Git with delta for diffs
- direnv with nix-direnv
- Node.js 24, Rust (via rustup)

**Desktop:**
- Aerospace tiling window manager (alt+hjkl navigation)
- LibreWolf browser with Sidebery, Bitwarden, Dark Reader

**Automation:**
- GitLab token rotation (Monday 09:00)

## Wireguard VPN

Private encrypted communication between hosts.

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

Edit `hosts/terminus/default.nix` and add to `modules.wireguard.peers`:

```nix
modules.wireguard = {
  enable = true;
  address = "10.100.0.1/24";
  peers = [
    {
      publicKey = "<new-device-public-key>";
      allowedIPs = [ "10.100.0.X/32" ];
    }
  ];
};
```

Rebuild: `sudo nixos-rebuild switch --flake /etc/nixos#terminus`

#### 3. Configure the new device

Create `/etc/wireguard/wg0.conf`:

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
