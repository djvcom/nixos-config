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

| Name | Purpose |
|------|---------|
| terminus | Primary development and hosting server |
