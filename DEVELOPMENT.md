# Development Guide

Common development tasks for the NixOS configuration.

## Quick Reference

```bash
just check    # Format and lint
just rebuild  # Build and switch (via nh)
just test     # Test without activation
just preflight # Upgrade pre-flight check
just update   # Update flake inputs
just clean    # Garbage collect (keeps 7d + 3 recent)
nix develop   # Enter dev shell (installs pre-commit hooks)
```

---

## Project Structure

```
~/.config/nixos/
├── flake.nix                              # Flake definition and inputs
├── flake.lock                             # Pinned dependency versions
├── justfile                               # Common tasks (nh-powered)
├── modules/
│   ├── features/
│   │   ├── base/                          # boot, packages, security, ssh, nix-settings
│   │   ├── server/                        # traefik, postgresql, acme, hardening, virtualisation
│   │   ├── desktop/                       # hyprland, nvidia, gaming, pipewire, fonts, jellyfin
│   │   ├── networking/wireguard.nix       # VPN configuration
│   │   ├── observability/                 # otel-collector, datadog-agent
│   │   ├── backup/restic.nix             # Restic backup to Garage S3
│   │   └── darwin/                        # macOS: homebrew, zscaler
│   ├── services/                          # kanidm, vaultwarden, stalwart, garage, openbao,
│   │                                      # valkey, roundcube, dashboard, djv, sidereal
│   ├── home/                              # base, shell, git, neovim/, ghostty, firefox,
│   │                                      # gitlab, aerospace, hyprland, waybar, cursor, wallpaper
│   ├── hosts/
│   │   ├── terminus/                      # Server: configuration, secrets, backup, observability, upgrade
│   │   ├── oshun/                         # Desktop: configuration, hardware, disko
│   │   ├── macbook-personal/              # macOS personal
│   │   └── macbook-work/                  # macOS work
│   ├── plumbing/                          # lib, overlays, checks, dev-shell, formatter,
│   │                                      # flake-modules, git-hooks, darwin-configs
│   └── tools/                             # agenix, disko, home-manager
├── overlays/                              # vaultwarden-sso, opentelemetry-collector, garage-v2
└── secrets/
    ├── secrets.nix                        # Secret key declarations
    └── *.age                              # Encrypted secrets
```

All `.nix` files under `modules/` are auto-discovered by import-tree and imported as flake-parts modules.

---

## Adding a New Service

### 1. Create service module

Create a new file in `modules/services/`:

```nix
# modules/services/myservice.nix
_:

{
  flake.modules.nixos.myservice =
    { config, pkgs, ... }:
    {
      services.myservice = {
        enable = true;
        # Configuration here
      };
    };
}
```

The module is auto-discovered by import-tree — no manual import needed.

### 2. Import in host configuration

Add the module to the host's imports in `modules/hosts/terminus/configuration.nix`:

```nix
imports = with inputs.self.modules.nixos; [
  # ... existing imports
  myservice
];
```

### 3. Add Traefik routing

In `modules/features/server/traefik.nix`, add the domain to the `domains` let binding:

```nix
domains = {
  # ... existing domains
  myservice = {
    host = "myservice.djv.sh";
    backend = "http://127.0.0.1:PORT";
  };
};
```

Then add router and service in `dynamicConfigOptions.http`:

```nix
routers.myservice = {
  rule = "Host(`${domains.myservice.host}`)";
  service = "myservice";
  middlewares = [ "security-headers" ];
  tls.certResolver = "letsencrypt";
  entryPoints = [ "websecure" ];
};

services.myservice.loadBalancer.servers = [
  { url = domains.myservice.backend; }
];
```

### 4. Add DNS record

Add an A record in Cloudflare pointing `myservice.djv.sh` to `88.99.1.188`.

---

## Managing Secrets

Secrets are managed with [agenix](https://github.com/ryantm/agenix).

### Adding a new secret

1. Create the secret file:

```bash
cd ~/.config/nixos/secrets
echo "my-secret-value" | agenix -e myservice-secret.age
```

2. Register in `secrets/secrets.nix`:

```nix
{
  # ... existing secrets
  "myservice-secret.age".publicKeys = allKeys;
}
```

3. Declare in `modules/hosts/terminus/secrets.nix`:

```nix
age.secrets.myservice-secret = {
  file = ../../secrets/myservice-secret.age;
  owner = "myservice";
  group = "myservice";
  mode = "0400";
};
```

4. Reference in service config:

```nix
services.myservice.secretFile = config.age.secrets.myservice-secret.path;
```

### Editing existing secrets

```bash
cd ~/.config/nixos/secrets
agenix -e myservice-secret.age
```

### Re-keying secrets

If keys change (new host, rotated user key):

```bash
cd ~/.config/nixos/secrets
agenix --rekey
```

### Rotating secrets

**Individual service secrets:**

```bash
cd ~/.config/nixos/secrets
head -c 32 /dev/urandom | base64 | agenix -e myservice-secret.age
just rebuild
sudo systemctl restart myservice
```

**OAuth2 client secrets (Kanidm):**

Client secrets are managed declaratively via `basicSecretFile`. To rotate:

```bash
head -c 32 /dev/urandom | base64
cd ~/.config/nixos/secrets
echo "<new-secret>" | agenix -e kanidm-oauth2-myservice.age
just rebuild
sudo systemctl restart kanidm
```

---

## Adding a New Host

### NixOS

1. Create host directory structure:

```bash
mkdir -p modules/hosts/newhostname
```

2. Create `modules/hosts/newhostname/configuration.nix`:

```nix
_:

{
  flake.modules.nixos.newhostname =
    { config, lib, pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        base-packages
        nix-settings
        ssh
        security
      ];

      networking.hostName = "newhostname";
      system.stateVersion = "25.05";
    };
}
```

3. Create `modules/hosts/newhostname/flake-config.nix`:

```nix
{ inputs, ... }:

{
  flake.nixosConfigurations.newhostname = inputs.self.lib.mkNixos {
    hostname = "newhostname";
  };
}
```

4. Generate `hardware.nix` and add host key to `secrets/secrets.nix`.

5. Deploy with `nixos-anywhere` (new server) or `nh os switch` (existing):

```bash
# New server with disko
nixos-anywhere --flake .#newhostname root@<ip>

# Existing server
nh os switch . -H newhostname
```

---

## Testing Changes

### Dry run (no activation)

```bash
just test
```

### Build only

```bash
just build
```

### Check syntax and style

```bash
just check
```

### Full rebuild

```bash
just rebuild
```

---

## Debugging

### Service logs

```bash
journalctl -u servicename -f
```

### Systemd unit status

```bash
systemctl status servicename
```

### Traefik routing issues

```bash
journalctl -u traefik -f
ls -la /var/lib/traefik/acme.json
```

### Agenix secrets not decrypting

```bash
ls -la /run/agenix/
ssh-add -l
age -d -i ~/.ssh/id_ed25519 secrets/test.age
```

### PostgreSQL issues

```bash
sudo -u postgres psql
\l    # list databases
\du   # list users
sudo -u dan psql djv
```

---

## Updating Dependencies

### Update all flake inputs

```bash
just update
```

### Update specific input

```bash
nix flake update nixpkgs
```

---

## Commit Conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat(scope):` — New feature
- `fix(scope):` — Bug fix
- `docs(scope):` — Documentation
- `refactor(scope):` — Code restructuring
- `chore(scope):` — Maintenance tasks

Examples:

```
feat(kanidm): add OIDC client for new service
fix(stalwart): correct DKIM signature algorithm
refactor(traefik): extract middleware configuration
docs: update disaster recovery guide
```

---

## Common Patterns

### Service with PostgreSQL database

```nix
{ config, ... }:

{
  services.myservice = {
    enable = true;
    database.url = "postgresql://myservice@/myservice?host=/run/postgresql";
  };

  services.postgresql = {
    ensureDatabases = [ "myservice" ];
    ensureUsers = [
      {
        name = "myservice";
        ensureDBOwnership = true;
      }
    ];
  };
}
```

### Service with ACME certificate

For services that terminate TLS themselves (not via Traefik):

```nix
{ config, ... }:

{
  security.acme.certs."myservice.djv.sh" = {
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets.cloudflare-dns-token.path;
    group = "myservice";
  };

  services.myservice = {
    tlsCert = "/var/lib/acme/myservice.djv.sh/fullchain.pem";
    tlsKey = "/var/lib/acme/myservice.djv.sh/key.pem";
  };
}
```

### Shared secret between services

Use a shared group:

```nix
{
  users.groups.shared-secret = { };

  age.secrets.shared-secret = {
    file = ../../secrets/shared-secret.age;
    owner = "root";
    group = "shared-secret";
    mode = "0440";
  };

  users.users.service1.extraGroups = [ "shared-secret" ];
  users.users.service2.extraGroups = [ "shared-secret" ];
}
```

---

## SSO with Kanidm

Kanidm provides OIDC authentication for services. OIDC clients are configured declaratively in `modules/services/kanidm.nix`.

### Adding an OIDC client

```nix
# In modules/services/kanidm.nix
systems.oauth2.myservice = {
  displayName = "My Service";
  originUrl = "https://myservice.djv.sh/";
  originLanding = "https://myservice.djv.sh/";
  preferShortUsername = true;
  scopeMaps.infrastructure_admins = [
    "openid"
    "profile"
    "email"
  ];
};
```

### Retrieving OIDC client secrets

After rebuild, get the client secret:

```bash
kanidm system oauth2 show-basic-secret myservice
```

Store in agenix and reference via environment file.

---

## Useful Commands

```bash
# Show current system generation
nixos-rebuild list-generations

# Roll back to previous generation
sudo nixos-rebuild switch --rollback

# Show flake outputs
nix flake show

# Check flake for issues
nix flake check

# Enter nix shell with tools
nix develop

# Browse dependency tree
nix-tree .#nixosConfigurations.terminus.config.system.build.toplevel

# Query installed packages
nix-store -q --references /run/current-system
```
