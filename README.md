# NixOS Configuration

NixOS configuration for personal development and hosting infrastructure.

## Structure

```
├── configuration.nix      # System configuration
├── home.nix               # User environment (home-manager)
├── hardware-configuration.nix  # Hardware-specific (not tracked)
├── secrets.nix            # Sensitive values (not tracked)
└── secrets.nix.example    # Template for secrets.nix
```

## Setup

1. Copy `secrets.nix.example` to `secrets.nix`
2. Fill in your values (IP addresses, SSH keys, etc.)
3. Run `sudo nixos-rebuild switch`

## Hosts

| Name | Purpose |
|------|---------|
| terminus | Primary development and hosting server |
