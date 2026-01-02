# Disaster Recovery Guide

This document covers full system recovery from scratch, including restoring data from backups.

## Pre-requisites

Before starting recovery, ensure you have:

1. **SSH private key** matching one of the authorised keys:
   - `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHifaRXUcEaoTkf8dJF4qB7V9+VTjYX++fRbOKoCCpC2`
   - `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3DO7MvH49txkJjxZDZb4S3IWdeuEvN3UzPGbkvEtbE`

2. **Age identity file** for decrypting agenix secrets (typically at `~/.config/sops/age/keys.txt`)

3. **Hetzner Cloud access** for firewall configuration

4. **Cloudflare access** for DNS management

5. **Backup credentials** (MinIO access, restic password) - stored in `secrets/backup-credentials.age`

---

## 1. DNS Configuration

Ensure these DNS records exist in Cloudflare for `djv.sh`:

| Type  | Name     | Target              |
|-------|----------|---------------------|
| A     | @        | 88.99.1.188         |
| A     | auth     | 88.99.1.188         |
| A     | bao      | 88.99.1.188         |
| A     | mail     | 88.99.1.188         |
| A     | minio    | 88.99.1.188         |
| A     | state    | 88.99.1.188         |
| A     | vault    | 88.99.1.188         |
| AAAA  | @        | 2a01:4f8:173:28ab::2|
| MX    | @        | mail.djv.sh (10)    |
| TXT   | @        | v=spf1 mx ~all      |
| TXT   | _dmarc   | v=DMARC1; p=none    |
| TXT   | mail._domainkey | (RSA DKIM public key) |
| TXT   | ed._domainkey   | (Ed25519 DKIM public key) |

---

## 2. Hetzner Firewall

Configure the Hetzner Cloud firewall with these inbound rules:

| Protocol | Port | Source    | Description       |
|----------|------|-----------|-------------------|
| TCP      | 22   | 0.0.0.0/0 | SSH (via sslh)    |
| TCP      | 443  | 0.0.0.0/0 | HTTPS (via sslh)  |
| TCP      | 25   | 0.0.0.0/0 | SMTP              |
| TCP      | 465  | 0.0.0.0/0 | SMTPS             |
| TCP      | 587  | 0.0.0.0/0 | SMTP Submission   |
| TCP      | 993  | 0.0.0.0/0 | IMAPS             |
| ICMP     | -    | 0.0.0.0/0 | Ping              |

---

## 3. Fresh NixOS Installation

### 3.1 Boot into rescue mode

From Hetzner Cloud console, boot the server into rescue mode.

### 3.2 Install using nixos-anywhere

```bash
# From your local machine with nix installed
nix run github:nix-community/nixos-anywhere -- \
  --flake github:djvcom/nixos-config#terminus \
  --target-host root@88.99.1.188
```

### 3.3 First boot tasks

After reboot, SSH in as `dan`:

```bash
ssh dan@88.99.1.188 -p 443
```

Verify basic services are running:

```bash
systemctl status traefik
systemctl status postgresql
systemctl status kanidm
```

---

## 4. OpenBao Initialisation

OpenBao uses Raft storage and needs initialisation on first boot:

```bash
# Check if already initialised
bao status

# If not initialised (exit code 2):
bao operator init -key-shares=1 -key-threshold=1
```

**Save the root token and unseal key securely!**

The unseal key is stored encrypted in `secrets/openbao-keys.age`.

### Unsealing after reboot

```bash
# Get unseal key
sudo cat /run/agenix/openbao-keys

# Unseal
bao operator unseal <unseal-key>
```

---

## 5. Restore from Backup

Backups are stored in MinIO at `s3://backups` using restic.

### 5.1 Get backup credentials

```bash
sudo cat /run/agenix/backup-credentials
# Contains RESTIC_PASSWORD, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
```

### 5.2 List available snapshots

```bash
source <(sudo cat /run/agenix/backup-credentials)
export RESTIC_REPOSITORY="s3:http://127.0.0.1:9000/backups"

restic snapshots
```

### 5.3 Restore file-based services

```bash
# Stop services before restore
sudo systemctl stop kanidm stalwart-mail openbao

# Restore Kanidm data
restic restore latest --target / --include /var/lib/kanidm --include /var/backup/kanidm

# Restore Stalwart mail data
restic restore latest --target / --include /var/lib/stalwart-mail/data

# Restore OpenBao data
restic restore latest --target / --include /var/lib/openbao

# Restart services
sudo systemctl start kanidm stalwart-mail openbao
```

### 5.4 Restore PostgreSQL databases

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

## 6. Service-Specific Recovery

### 6.1 Kanidm

After restore, verify:

```bash
# Check service status
systemctl status kanidm

# Test authentication (from local machine)
curl -v https://auth.djv.sh
```

If provisioning fails, check secrets are accessible:

```bash
sudo cat /run/agenix/kanidm-admin-password
sudo cat /run/agenix/kanidm-idm-admin-password
```

### 6.2 Stalwart Mail

Verify DKIM keys are accessible:

```bash
sudo cat /run/agenix/dkim-rsa-key
sudo cat /run/agenix/dkim-ed25519-key
```

Test mail delivery:

```bash
# Send test email
echo "Test" | mail -s "Recovery test" dan@djv.sh
```

Check mail logs:

```bash
journalctl -u stalwart-mail -f
```

### 6.3 Vaultwarden

Vaultwarden data is in PostgreSQL. After database restore:

```bash
systemctl restart vaultwarden

# Verify access
curl -v https://vault.djv.sh
```

### 6.4 MinIO

MinIO data lives at `/var/lib/minio/data`. If restoring from external backup:

```bash
# Restore data directory
restic restore latest --target / --include /var/lib/minio/data

# Fix permissions
sudo chown -R minio:minio /var/lib/minio

# Restart
sudo systemctl restart minio
```

---

## 7. Verification Checklist

After recovery, verify each service:

- [ ] **SSH**: `ssh dan@djv.sh -p 443`
- [ ] **HTTPS**: All domains respond with valid certificates
- [ ] **Kanidm**: Can log in at https://auth.djv.sh
- [ ] **Vaultwarden**: Can log in at https://vault.djv.sh
- [ ] **OpenBao**: Unsealed and UI accessible at https://bao.djv.sh
- [ ] **Mail**: Can send/receive email via IMAP/SMTP
- [ ] **djv.sh**: Portfolio site loads correctly
- [ ] **MinIO**: Console accessible at https://minio.djv.sh
- [ ] **Backups**: Timer running (`systemctl status restic-backup.timer`)
- [ ] **Observability**: Logs appearing in Datadog

---

## 8. Emergency Contacts

- **Hetzner Support**: https://console.hetzner.cloud
- **Cloudflare Support**: https://dash.cloudflare.com
- **NixOS Discourse**: https://discourse.nixos.org

---

## 9. Manual Backup

To create an immediate backup:

```bash
sudo systemctl start restic-backup.service
journalctl -u restic-backup -f
```

To verify backup integrity:

```bash
source <(sudo cat /run/agenix/backup-credentials)
export RESTIC_REPOSITORY="s3:http://127.0.0.1:9000/backups"
restic check
```
