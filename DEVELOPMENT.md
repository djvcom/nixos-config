# Development Guide

This document covers common development tasks for the NixOS configuration.

## Quick Reference

```bash
just check    # Format and lint
just rebuild  # Build and switch
just test     # Test without activation
just preflight # Upgrade pre-flight check
just update   # Update flake inputs
just clean    # Garbage collect
```

---

## Project Structure

```
~/.config/nixos/
├── flake.nix                 # Flake definition and inputs
├── flake.lock                # Pinned dependency versions
├── hosts/
│   └── terminus/
│       ├── default.nix       # Main host config (networking, users, systemd)
│       ├── hardware.nix      # Hardware-specific config
│       ├── disko.nix         # Disk partitioning
│       ├── host-secrets.nix  # Agenix secret declarations
│       ├── hardening.nix     # Kernel and network security
│       ├── traefik.nix       # Reverse proxy configuration
│       └── services/
│           ├── djv.nix       # Portfolio site
│           ├── kanidm.nix    # Identity provider
│           ├── vaultwarden.nix # Password manager
│           ├── openbao.nix   # Secrets management
│           ├── stalwart.nix  # Mail server
│           └── minio.nix     # Object storage
├── modules/
│   ├── base.nix              # Common settings for all hosts
│   ├── observability.nix     # OTEL collector and Datadog export
│   └── backup.nix            # Restic backup configuration
├── home/
│   └── dan.nix               # Home-manager configuration
└── secrets/
    ├── secrets.nix           # Secret key declarations
    └── *.age                  # Encrypted secrets
```

---

## Adding a New Service

### 1. Create service file

Create a new file in `hosts/terminus/services/`:

```nix
# hosts/terminus/services/myservice.nix
{ config, pkgs, ... }:

{
  services.myservice = {
    enable = true;
    # Configuration here
  };
}
```

### 2. Import in default.nix

Add to the imports list in `hosts/terminus/default.nix`:

```nix
imports = [
  # ... existing imports
  ./services/myservice.nix
];
```

### 3. Add Traefik routing

In `hosts/terminus/traefik.nix`, add the domain to the `domains` let binding:

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

3. Declare in `hosts/terminus/host-secrets.nix`:

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
# Generate new value and encrypt
echo "new-secret-value" | agenix -e myservice-secret.age
# Or for random values:
head -c 32 /dev/urandom | base64 | agenix -e myservice-secret.age

# Rebuild to deploy
just rebuild

# Restart affected service
sudo systemctl restart myservice
```

**Rotating agenix master keys:**

1. Generate new SSH key:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_new -C "dan@terminus"
```

2. Update `secrets/secrets.nix` with new public key:

```nix
let
  dan = "ssh-ed25519 AAAA...new-key...";
in
```

3. Re-encrypt all secrets:

```bash
cd ~/.config/nixos/secrets
# Keep old key available for decryption
SSH_AUTH_SOCK="" ssh-add ~/.ssh/id_ed25519
agenix --rekey
```

4. Replace old key with new key, rebuild.

**OAuth2 client secrets (Kanidm):**

Client secrets are managed declaratively via `basicSecretFile`. To rotate:

```bash
# Generate new secret
head -c 32 /dev/urandom | base64

# Encrypt for Kanidm
cd ~/.config/nixos/secrets
echo "<new-secret>" | agenix -e kanidm-oauth2-myservice.age

# For Vaultwarden, also update the SSO env file
echo "SSO_CLIENT_SECRET=<new-secret>" | agenix -e vaultwarden-sso.age

# Rebuild and restart
just rebuild
sudo systemctl restart kanidm vaultwarden
```

**Kanidm admin passwords:**

```bash
# Generate new password
head -c 32 /dev/urandom | base64

# Update encrypted file
cd ~/.config/nixos/secrets
echo "<new-password>" | agenix -e kanidm-admin-password.age

# Rebuild - provisioning will update the password
just rebuild
```

---

## Adding a New Host

1. Create host directory structure:

```bash
mkdir -p hosts/newhostname/services
```

2. Create minimal `default.nix`:

```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/base.nix
  ];

  networking.hostName = "newhostname";

  # Host-specific configuration

  system.stateVersion = "25.05";
}
```

3. Generate `hardware.nix`:

```bash
nixos-generate-config --show-hardware-config > hosts/newhostname/hardware.nix
```

4. Add to `flake.nix`:

```nix
nixosConfigurations.newhostname = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./hosts/newhostname
    # ... other modules
  ];
};
```

5. Add host key to `secrets/secrets.nix`:

```nix
let
  newhostname = "ssh-ed25519 AAAA...";
  allKeys = [ terminus dan newhostname ];
in
# ...
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
# Check Traefik logs
journalctl -u traefik -f

# Check certificate status
ls -la /var/lib/traefik/acme.json
```

### Agenix secrets not decrypting

```bash
# Check if secret file exists
ls -la /run/agenix/

# Verify age identity
ssh-add -l

# Manual decrypt test
age -d -i ~/.ssh/id_ed25519 secrets/test.age
```

### PostgreSQL issues

```bash
# Connect as postgres superuser
sudo -u postgres psql

# List databases
\l

# List users
\du

# Connect to specific database
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
nix flake lock --update-input nixpkgs
```

### Check for updates without applying

```bash
nix flake update --dry-run
```

---

## Commit Conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat(scope):` - New feature
- `fix(scope):` - Bug fix
- `docs(scope):` - Documentation
- `refactor(scope):` - Code restructuring
- `chore(scope):` - Maintenance tasks

Examples:

```
feat(kanidm): add OIDC client for new service
fix(stalwart): correct DKIM signature algorithm
refactor(traefik): extract middleware configuration
docs: add disaster recovery guide
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

  # Ensure database exists
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

Kanidm provides OIDC authentication for services. OIDC clients are configured declaratively in `services/kanidm.nix`.

### Adding an OIDC client

```nix
# In services/kanidm.nix
systems.oauth2.myservice = {
  displayName = "My Service";
  originUrl = "https://myservice.djv.sh/";
  originLanding = "https://myservice.djv.sh/";
  preferShortUsername = true;
  # PKCE is enabled by default in Kanidm
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

### Vaultwarden SSO

Vaultwarden uses environment variables for SSO. The Kanidm client is already configured.

After rebuild, update the secret:

```bash
# Get the client secret
kanidm system oauth2 show-basic-secret vaultwarden

# Update the secret (creates new encrypted file)
cd ~/.config/nixos/secrets
echo "SSO_CLIENT_SECRET=<secret-from-above>" | agenix -e vaultwarden-sso.age

# Restart Vaultwarden to pick up new secret
sudo systemctl restart vaultwarden
```

### OpenBao OIDC

OpenBao requires CLI configuration after unsealing (cannot be declarative).

```bash
# Ensure OpenBao is unsealed first
bao status

# Enable OIDC auth method
bao auth enable oidc

# Get client secret from Kanidm
kanidm system oauth2 show-basic-secret openbao

# Configure OIDC
bao write auth/oidc/config \
    oidc_discovery_url="https://auth.djv.sh/oauth2/openid/openbao" \
    oidc_client_id="openbao" \
    oidc_client_secret="<secret-from-kanidm>" \
    default_role="admin"

# Create admin role
bao write auth/oidc/role/admin \
    role_type="oidc" \
    user_claim="preferred_username" \
    groups_claim="groups" \
    policies="admin,default" \
    oidc_scopes="openid,profile,email,groups" \
    allowed_redirect_uris="https://bao.djv.sh/ui/vault/auth/oidc/oidc/callback"

# Test login via UI at https://bao.djv.sh
# Select "OIDC" method and click "Sign in with OIDC Provider"
```

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

# Query installed packages
nix-store -q --references /run/current-system
```
