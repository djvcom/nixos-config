# Disaster Recovery Guide

Full system recovery from scratch, including restoring data from backups.

## Pre-requisites

Before starting recovery, ensure you have:

1. **SSH private key** matching one of the authorised keys in `secrets/secrets.nix`

2. **Age identity file** for decrypting agenix secrets

3. **Hetzner Cloud access** for firewall configuration

4. **Cloudflare access** for DNS management

5. **Backup credentials** (Garage S3 access, restic password) — stored in `secrets/backup-credentials.age`

---

## 1. DNS Configuration

Ensure these DNS records exist in Cloudflare for `djv.sh`:

| Type  | Name     | Target              |
|-------|----------|---------------------|
| A     | @        | 88.99.1.188         |
| A     | auth     | 88.99.1.188         |
| A     | s3       | 88.99.1.188         |
| A     | sidereal | 88.99.1.188         |
| A     | vault    | 88.99.1.188         |
| AAAA  | @        | 2a01:4f8:173:28ab::2|

Mail for `djv.sh` is handled by Cloudflare Email Routing rather than terminus, so its
MX and SPF records are managed from the Cloudflare dashboard.

---

## 2. Hetzner Firewall

Configure the Hetzner Cloud firewall with these inbound rules:

| Protocol | Port | Source    | Description       |
|----------|------|-----------|-------------------|
| TCP      | 22   | 0.0.0.0/0 | SSH (via sslh)    |
| TCP      | 443  | 0.0.0.0/0 | HTTPS (via sslh)  |
| ICMP     | -    | 0.0.0.0/0 | Ping              |

---

## 3. Fresh NixOS Installation

### 3.1 Boot into rescue mode

From Hetzner Cloud console, boot the server into rescue mode.

### 3.2 Install using nixos-anywhere

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake github:djvcom/nixos-config#terminus \
  --target-host root@88.99.1.188
```

### 3.3 First boot tasks

After reboot, SSH in as `dan`:

```bash
ssh dan@djv.sh -p 443
```

Verify basic services are running:

```bash
systemctl status traefik
systemctl status postgresql
systemctl status kanidm
```

---

## 4. Restore from Backup

Backups are stored in Garage at `s3://backups` using restic.

### 4.1 Get backup credentials

```bash
sudo cat /run/agenix/backup-credentials
# Contains RESTIC_PASSWORD, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
```

### 4.2 List available snapshots

```bash
source <(sudo cat /run/agenix/backup-credentials)
export RESTIC_REPOSITORY="s3:http://127.0.0.1:3900/backups"

restic snapshots
```

### 4.3 Restore file-based services

```bash
# Stop services before restore
sudo systemctl stop kanidm

# Restore Kanidm data
restic restore latest --target / --include /var/lib/kanidm --include /var/backup/kanidm

# Restart services
sudo systemctl start kanidm
```

### 4.4 Restore PostgreSQL databases

PostgreSQL dumps are stored within the backup as SQL files:

```bash
# List database dumps
restic ls latest /var/backup/postgresql

# Restore to temporary location
restic restore latest --target /tmp/restore --include /var/backup/postgresql

# Restore djv database
sudo -u postgres psql djv < /tmp/restore/var/backup/postgresql/djv.sql

# Restore vaultwarden database
sudo -u postgres psql vaultwarden < /tmp/restore/var/backup/postgresql/vaultwarden.sql

# Clean up
rm -rf /tmp/restore
```

---

## 5. Service-Specific Recovery

### 5.1 Kanidm

After restore, verify:

```bash
systemctl status kanidm
curl -v https://auth.djv.sh
```

If provisioning fails, check secrets are accessible:

```bash
sudo cat /run/agenix/kanidm-admin-password
sudo cat /run/agenix/kanidm-idm-admin-password
```

### 5.2 Vaultwarden

Vaultwarden data is in PostgreSQL. After database restore:

```bash
systemctl restart vaultwarden
curl -v https://vault.djv.sh
```

### 5.3 Garage

Garage data lives at `/var/lib/garage/data`. After a fresh install, Garage needs its cluster layout configured:

```bash
# Check node ID
garage status

# Assign capacity
garage layout assign -z dc1 -c 1T <node-id>

# Apply layout
garage layout apply --version 1
```

If restoring from external backup:

```bash
restic restore latest --target / --include /var/lib/garage/data
sudo chown -R garage:garage /var/lib/garage
sudo systemctl restart garage
```

---

## 6. Verification Checklist

After recovery, verify each service:

- [ ] **SSH**: `ssh dan@djv.sh -p 443`
- [ ] **HTTPS**: All domains respond with valid certificates
- [ ] **Kanidm**: Can log in at https://auth.djv.sh
- [ ] **Vaultwarden**: Can log in at https://vault.djv.sh
- [ ] **djv.sh**: Portfolio site loads correctly
- [ ] **Garage**: S3 API at https://s3.djv.sh
- [ ] **Backups**: Timer running (`systemctl status restic-backup.timer`)
- [ ] **Observability**: Logs appearing in Datadog

---

## 7. Emergency Contacts

- **Hetzner Support**: https://console.hetzner.cloud
- **Cloudflare Support**: https://dash.cloudflare.com
- **NixOS Discourse**: https://discourse.nixos.org

---

## 8. Manual Backup

To create an immediate backup:

```bash
sudo systemctl start restic-backup.service
journalctl -u restic-backup -f
```

To verify backup integrity:

```bash
source <(sudo cat /run/agenix/backup-credentials)
export RESTIC_REPOSITORY="s3:http://127.0.0.1:3900/backups"
restic check
```
