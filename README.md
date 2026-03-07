# Nix Configuration

NixOS and nix-darwin configuration for personal development infrastructure.

## Structure

```
├── flake.nix                           # Entry point, defines all inputs
├── flake.lock                          # Pinned dependencies
├── justfile                            # Common tasks (nh-powered)
├── modules/
│   ├── features/
│   │   ├── base/                       # Boot, packages, security, SSH, nix settings
│   │   ├── server/                     # Traefik, PostgreSQL, ACME, hardening, virtualisation
│   │   ├── desktop/                    # Hyprland, Nvidia, gaming, audio, fonts, Jellyfin
│   │   ├── networking/                 # WireGuard VPN
│   │   ├── observability/              # OTEL collector, Datadog agent
│   │   ├── backup/                     # Restic backup to Garage S3
│   │   └── darwin/                     # macOS (Homebrew, Zscaler)
│   ├── services/
│   │   ├── kanidm.nix                  # Identity provider (OIDC)
│   │   ├── vaultwarden.nix             # Password manager (SSO)
│   │   ├── stalwart.nix                # Mail server (SMTP/IMAP)
│   │   ├── garage.nix                  # S3 object storage
│   │   ├── openbao.nix                 # Secrets management
│   │   ├── valkey.nix                  # Cache/queue store
│   │   ├── roundcube.nix               # Webmail (OAuth2)
│   │   ├── dashboard.nix              # Homepage dashboard (OAuth2)
│   │   ├── djv.nix                     # Portfolio site
│   │   └── sidereal.nix               # Build/container service
│   ├── home/
│   │   ├── base.nix                    # Shared packages and session config
│   │   ├── shell.nix                   # Bash/Zsh, aliases, starship, direnv
│   │   ├── git.nix                     # Git config with delta
│   │   ├── neovim/                     # NixVim config (split by concern)
│   │   ├── ghostty.nix                 # Ghostty terminal config
│   │   ├── firefox.nix                 # LibreWolf with extensions
│   │   ├── aerospace.nix              # Tiling window manager (macOS)
│   │   └── gitlab.nix                  # GitLab token rotation
│   ├── hosts/
│   │   ├── terminus/                   # NixOS server (Hetzner)
│   │   ├── oshun/                      # NixOS desktop (local)
│   │   ├── macbook-personal/           # nix-darwin personal laptop
│   │   └── macbook-work/               # nix-darwin work laptop
│   ├── plumbing/                       # Flake infrastructure
│   │   ├── lib.nix                     # mkNixos, mkDarwin helpers
│   │   ├── overlays.nix                # Nixpkgs overlay registry
│   │   ├── dev-shell.nix               # nix develop environment
│   │   ├── git-hooks.nix               # Pre-commit hooks (nixfmt, statix, deadnix)
│   │   ├── checks.nix                  # CI build checks
│   │   └── formatter.nix               # nix fmt configuration
│   └── tools/                          # agenix, disko, home-manager
├── overlays/                           # Nixpkgs package overlays
└── secrets/
    ├── secrets.nix                     # Defines who can decrypt
    └── *.age                           # Encrypted secrets (agenix)
```

## Hosts

| Name | Platform | Purpose |
|------|----------|---------|
| terminus | NixOS (x86_64) | Primary server — identity, mail, storage, secrets, web |
| oshun | NixOS (x86_64) | Desktop — gaming, media, development |
| macbook-personal | macOS (aarch64) | Personal laptop |
| macbook-work | macOS (aarch64) | Work laptop |

## Adding a New Host

### NixOS

1. Create `modules/hosts/newhost/configuration.nix`:
   ```nix
   _:

   {
     flake.modules.nixos.newhost = {
       imports = with inputs.self.modules.nixos; [
         base-packages
         nix-settings
         ssh
         security
       ];

       networking.hostName = "newhost";
       system.stateVersion = "25.05";
     };
   }
   ```

2. Create `modules/hosts/newhost/flake-config.nix`:
   ```nix
   { inputs, ... }:

   {
     flake.nixosConfigurations.newhost = inputs.self.lib.mkNixos {
       hostname = "newhost";
     };
   }
   ```

3. Add host key to `secrets/secrets.nix`

4. Deploy:
   ```bash
   # New server with disko
   nixos-anywhere --flake .#newhost root@<ip>

   # Existing server
   nh os switch . -H newhost
   ```

### macOS (nix-darwin)

1. Create `modules/hosts/macbook-new/configuration.nix` (see existing macbook configs)

2. Bootstrap:
   ```bash
   nix --extra-experimental-features "nix-command flakes" run nix-darwin -- \
     switch --flake ~/.config/nixos#macbook-new --impure
   ```

3. Subsequent rebuilds:
   ```bash
   rebuild
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
3. Declare in the host's secrets module
4. Reference in service config via `config.age.secrets.<name>.path`

## What's Included (macOS)

**System:**
- Homebrew managed declaratively (Ghostty, Chrome)
- Touch ID for sudo
- Passwordless `darwin-rebuild`

**Terminal:**
- Ghostty with Catppuccin Mocha theme, 90% opacity
- Zsh with autosuggestions, syntax highlighting
- Starship prompt
- Modern CLI tools: eza, bat, delta, fzf, ripgrep, fd, bottom, dust, procs

**Development:**
- Neovim via NixVim with LSP (Rust, TypeScript, Nix, Terraform), treesitter, telescope
- Git with delta for diffs
- direnv with nix-direnv
- Node.js 24, Rust (via rustup)

**Desktop:**
- Aerospace tiling window manager (alt+hjkl navigation)
- LibreWolf browser with Sidebery, Bitwarden, Dark Reader

**Automation:**
- GitLab token rotation (Monday 09:00)

## WireGuard VPN

Private encrypted communication between hosts.

### Network Details

- **Subnet**: 10.100.0.0/24
- **Hub**: terminus (10.100.0.1)
- **Port**: UDP 51820

### Adding a New Peer

1. Generate keys on the new device:
   ```bash
   wg genkey | tee privatekey | wg pubkey > publickey
   ```

2. Add the peer to terminus in `modules/hosts/terminus/configuration.nix`:
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

3. Rebuild: `nh os switch . -H terminus`

4. Configure the new device with `/etc/wireguard/wg0.conf`:
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

5. Connect: `sudo wg-quick up wg0`

### IP Allocation

| IP | Device |
|----|--------|
| 10.100.0.1 | terminus |
| 10.100.0.2-254 | Available for new peers |
