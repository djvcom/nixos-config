# Security Hardening Reference

This document provides authoritative references for the security measures
implemented in this NixOS configuration.

## Kernel Hardening (CIS Benchmarks)

The kernel sysctls in `hosts/terminus/default.nix` follow CIS Benchmark
recommendations and Linux kernel security best practices.

### Network Stack

| Setting | Value | Purpose | Reference |
|---------|-------|---------|-----------|
| `net.ipv4.tcp_syncookies` | 1 | Mitigate SYN flood DoS attacks | [CIS 3.3.8](https://www.cisecurity.org/cis-benchmarks) |
| `net.ipv4.conf.all.accept_redirects` | 0 | Prevent ICMP redirect attacks | [CIS 3.2.2](https://www.cisecurity.org/cis-benchmarks) |
| `net.ipv4.conf.all.send_redirects` | 0 | Disable ICMP redirect sending | [CIS 3.2.3](https://www.cisecurity.org/cis-benchmarks) |
| `net.ipv4.conf.all.rp_filter` | 1 | Reverse path filtering (anti-spoofing) | [CIS 3.3.7](https://www.cisecurity.org/cis-benchmarks) |
| `net.ipv4.conf.all.log_martians` | 1 | Log packets with impossible addresses | [CIS 3.2.4](https://www.cisecurity.org/cis-benchmarks) |

### Kernel Security

| Setting | Value | Purpose | Reference |
|---------|-------|---------|-----------|
| `kernel.kptr_restrict` | 2 | Hide kernel pointers (KASLR protection) | [Kernel docs](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/kernel.html) |
| `kernel.dmesg_restrict` | 1 | Restrict dmesg to CAP_SYSLOG | [Kernel docs](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/kernel.html) |
| `kernel.perf_event_paranoid` | 3 | Restrict perf to CAP_SYS_ADMIN | [Kernel perf security](https://www.kernel.org/doc/html/v6.0/admin-guide/perf-security.html) |
| `kernel.unprivileged_bpf_disabled` | 1 | Disable unprivileged eBPF | [SUSE KB](https://www.suse.com/support/kb/doc/?id=000020545) |
| `net.core.bpf_jit_harden` | 2 | Harden BPF JIT compiler | [Kernel net docs](https://docs.kernel.org/admin-guide/sysctl/net.html) |

## SSH Hardening

Configuration in `modules/base.nix` follows NIST and CIS guidelines.

| Setting | Value | Purpose | Reference |
|---------|-------|---------|-----------|
| `PasswordAuthentication` | no | Enforce key-based auth | [NIST IR 7966](https://nvlpubs.nist.gov/nistpubs/ir/2015/NIST.IR.7966.pdf) |
| `PermitRootLogin` | no | Prevent direct root access | [CIS 5.2.8](https://www.cisecurity.org/cis-benchmarks) |
| `KbdInteractiveAuthentication` | no | Disable keyboard-interactive | [NIST SP 800-123](https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-123.pdf) |

## PostgreSQL Authentication

Configuration in `hosts/terminus/default.nix` uses secure authentication methods.

| Method | Scope | Purpose | Reference |
|--------|-------|---------|-----------|
| `peer` | Local socket | OS user validation | [PostgreSQL docs](https://www.postgresql.org/docs/current/auth-peer.html) |
| `scram-sha-256` | Network | Challenge-response auth | [RFC 7677](https://datatracker.ietf.org/doc/html/rfc7677), [PostgreSQL docs](https://www.postgresql.org/docs/current/auth-password.html) |

SCRAM-SHA-256 is the most secure password method available in PostgreSQL,
providing protection against password sniffing and using secure hash storage.

## HTTP Security Headers

nginx configuration includes OWASP-recommended security headers.

| Header | Value | Purpose | Reference |
|--------|-------|---------|-----------|
| `X-Frame-Options` | SAMEORIGIN | Prevent clickjacking | [OWASP](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html) |
| `X-Content-Type-Options` | nosniff | Prevent MIME sniffing | [OWASP](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html) |
| `X-XSS-Protection` | 1; mode=block | Legacy XSS filter | [OWASP](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html) |
| `Referrer-Policy` | strict-origin-when-cross-origin | Control referrer leakage | [OWASP](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html) |

Note: Consider adding `Content-Security-Policy` for additional XSS protection.

## Brute Force Protection

fail2ban in `modules/base.nix` provides automated intrusion prevention.

- Monitors authentication logs for failed attempts
- Dynamically blocks attacking IPs via firewall
- Implements progressive ban time escalation

Reference: [Fail2ban documentation](https://www.fail2ban.org/)

## Authoritative Sources

### Standards and Frameworks
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks) - Center for Internet Security
- [NIST IR 7966](https://nvlpubs.nist.gov/nistpubs/ir/2015/NIST.IR.7966.pdf) - SSH Key Management
- [NIST SP 800-123](https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-123.pdf) - General Server Security
- [OWASP Cheat Sheets](https://cheatsheetseries.owasp.org/) - Web Security

### Official Documentation
- [Linux Kernel sysctl](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/) - Kernel parameters
- [PostgreSQL Authentication](https://www.postgresql.org/docs/current/auth-methods.html) - Auth methods
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - NixOS configuration
