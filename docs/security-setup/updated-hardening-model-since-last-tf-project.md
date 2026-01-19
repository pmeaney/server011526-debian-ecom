# Updated Hardening Model Since Last Terraform Project

This document outlines the revised security hardening strategy for the current infrastructure, adapted for an international mobile workflow.

---

## Context: International Business Workflow

**By "international business," we mean:** The developer working on this project will be working from various locations including:
- Home (residential ISP)
- Public libraries
- Coffee shops and cafes
- Different cities across the US
- Travel to Mexico

**Implication:** We cannot restrict SSH access to a single IP address. The developer needs to connect from any location, which means security must be layered differently than a typical "office-only" setup.

---

## Revised Hardening Strategy for Mobile Workflow

### Layer 1: DigitalOcean Cloud Firewall (via Terraform)

**Configuration:**
- Allow ports **80, 443** from **anywhere** (0.0.0.0/0) - Public web traffic
- Allow port **22** (SSH) from **anywhere** (0.0.0.0/0) - Developer needs access from any location
- **Block everything else**

**Why this works:**
- Can't restrict SSH to single IP (developer is mobile)
- Other layers provide the actual SSH protection
- Blocks unexpected ports (like the PayloadCMS botnet attack on port 3000)

### Layer 2: UFW Host Firewall (via cloud-init)

**Configuration:**
- Default deny incoming
- Default allow outgoing
- Allow ports: 22, 80, 443 only
- Enable on first boot

**What this blocks:**
- Any traffic to non-standard ports
- The PayloadCMS-style botnet attacks (hitting port 3000 directly)
- Port scanning attempts on unexpected ports
- Internal service exposure (databases, admin panels, etc.)

**Implementation:** Automated via cloud-init `runcmd` section

### Layer 3: Fail2ban (via cloud-init)

**This is the primary SSH protection layer for mobile workflows**

**Configuration:**
- Monitor SSH login attempts
- Ban IP after **3 failed attempts**
- Ban duration: 10 minutes (default) or longer
- Automatically unban after duration

**Why this works for mobile workflow:**
- Developer has correct SSH key → never triggers fail2ban
- Bots trying brute-force → banned after 3 attempts
- Developer's IP changes (cafe to cafe) → doesn't matter, they have the key
- Even if developer fat-fingers password 3 times → their IP is banned, but they can just switch to cellular hotspot or wait 10 minutes

**What this blocks:**
- SSH brute-force attacks (99% of SSH attacks)
- Automated bot scanning
- Dictionary attacks
- Credential stuffing attempts

**Implementation:** Automated via cloud-init (install fail2ban, enable sshd jail)

### Layer 4: SSH Key-Only Authentication (via cloud-init)

**Configuration:**
- Password authentication: **disabled**
- SSH key authentication: **required**
- Only two authorized keys:
  - Human developer key
  - GitHub Actions CICD bot key

**Why this works:**
- Even if attacker knows username, they can't login without private key
- Brute-force is impossible (no password to guess)
- Developer can login from anywhere with their key
- CICD bot can deploy from GitHub Actions

**What this blocks:**
- All password-based attacks
- Even if fail2ban fails, attacker still can't get in

**Implementation:** Already configured in cloud-init via `ssh_pwauth: false`

### Layer 5: Kernel Hardening (via cloud-init)

**Configuration (sysctl settings):**
- Enable SYN cookies (DDoS protection)
- Disable ICMP redirects
- Enable reverse path filtering
- Disable IPv6 (if not needed)
- Ignore ping requests (optional)

**What this blocks:**
- SYN flood attacks
- IP spoofing
- Network-level DDoS attempts
- Some reconnaissance techniques

**Implementation:** Can be added to cloud-init `runcmd` or `write_files` section

---

## How This Protects Against Known Attacks

### PayloadCMS Botnet Attack (Port 3000)

**Attack vector:** Bots directly hitting port 3000 (PayloadCMS default port)

**Blocked by:**
1. ✅ **UFW** - Port 3000 not allowed, packets dropped
2. ✅ **Cloud Firewall** - Port 3000 not allowed (if UFW somehow fails)

**Result:** Attack never reaches the application

### SSH Brute-Force from Random IPs

**Attack vector:** Bots trying common passwords on port 22

**Blocked by:**
1. ✅ **Fail2ban** - After 3 failed attempts, IP is banned
2. ✅ **SSH key-only auth** - Even if fail2ban fails, password auth is disabled

**Result:** Attack can't succeed

### Port Scanning

**Attack vector:** Attacker scans all 65,535 ports looking for services

**Blocked by:**
1. ✅ **UFW** - Only 22, 80, 443 respond
2. ✅ **Cloud Firewall** - Only 22, 80, 443 allowed

**Result:** Attacker sees only 3 open ports, all expected and hardened

### Developer Working from Mexico Cafe

**Scenario:** Developer needs to SSH from random cafe in Guadalajara

**Access granted by:**
1. ✅ **Cloud Firewall** - Allows SSH from anywhere
2. ✅ **UFW** - Allows port 22
3. ✅ **Fail2ban** - Doesn't trigger (developer has correct key)
4. ✅ **SSH key auth** - Developer authenticates successfully

**Result:** Seamless access from any location

---

## Comparison to Previous Project

### What Changed

**Previous approach (home-only workflow):**
- Could restrict SSH to home IP in cloud firewall
- Single point of access
- Simpler security model

**Current approach (mobile workflow):**
- Must allow SSH from anywhere
- Rely more heavily on fail2ban and SSH keys
- Slightly higher attack surface, but still very secure

### What Stayed the Same

- ✅ SSH key-only authentication
- ✅ UFW firewall
- ✅ Docker containerization
- ✅ Principle of least privilege

### What's Better Now

- ✅ Fail2ban properly configured (primary defense)
- ✅ Kernel hardening added
- ✅ DigitalOcean cloud firewall (defense in depth)
- ✅ Automated via cloud-init (no manual hardening)

---

## Optional Enhancement: Cloudflare

**If you add Cloudflare in front (recommended):**

**What it adds:**
- Hides your real server IP (harder to target directly)
- DDoS protection (absorbs massive traffic)
- Bot filtering (reduces noise)
- CDN (faster for users)

**What it doesn't change:**
- SSH still goes direct to server IP (Cloudflare doesn't proxy SSH)
- All the layers above still apply
- Mobile workflow still works the same

**Cost:** $0/month (free tier) + ~$12/year for domain

See `docs/next-steps-after-server-setup.md` for Cloudflare setup instructions.

---

## Security Trade-offs

### What We Accept

**Risk:** SSH accessible from any IP worldwide
**Mitigation:** 
- Fail2ban bans brute-force attempts
- SSH key-only (no password attacks possible)
- Monitoring can alert on unusual activity

**Risk:** Developer might lose SSH private key
**Mitigation:**
- Key stored in 1Password (backup)
- CICD bot key can be used for emergency access
- Can always rebuild server with new keys

### What We Don't Accept

**Not allowed:**
- ❌ Password authentication on SSH
- ❌ Root login via SSH
- ❌ Unnecessary open ports
- ❌ Applications exposed on non-standard ports
- ❌ Unpatched systems (auto-updates enabled)

---

## Implementation Checklist

**Via Terraform:**
- [ ] DigitalOcean cloud firewall resource (ports 22, 80, 443)

**Via cloud-init:**
- [ ] UFW installation and configuration
- [ ] Fail2ban installation and configuration
- [ ] SSH hardening (password auth disabled)
- [ ] Kernel hardening (sysctl settings)
- [ ] Automatic security updates

**Manual (post-deployment):**
- [ ] Cloudflare setup (optional)
- [ ] UptimeRobot monitoring
- [ ] Custom fail2ban jails for applications (optional)

---

## Monitoring & Response

### What to Monitor

**Weekly:**
- Review fail2ban banned IPs: `sudo fail2ban-client status sshd`
- Check for unusual login attempts: `sudo journalctl -u ssh | grep Failed`
- Review UFW logs: `sudo grep UFW /var/log/syslog`

**Monthly:**
- Review Cloudflare analytics (if using)
- Check system update status
- Verify fail2ban is running

### Red Flags

**Immediate investigation needed:**
- Successful SSH login from unknown IP
- Multiple IPs trying SSH simultaneously (coordinated attack)
- Unexpected services listening on ports
- Unusual outbound traffic

**Response:**
- Review logs immediately
- Ban suspicious IPs manually if needed
- Consider temporarily restricting SSH to known IP ranges
- Check all containers for compromise

---

## Future Enhancements

**When the business grows:**
- VPN for SSH access (Tailscale, WireGuard)
- Jump box / bastion host
- Multi-factor authentication for SSH
- IDS/IPS (intrusion detection/prevention)
- SIEM (security information and event management)

**For now:** The layered approach above is appropriate for a prototype/small business site.

---

## Summary

**The revised hardening model:**
1. Works for mobile/international workflow
2. Provides defense-in-depth (multiple layers)
3. Automated via Terraform and cloud-init
4. Protects against the PayloadCMS-style botnet attack
5. Allows developer to work from anywhere securely

**Key principle:** Can't rely on IP restrictions, so we rely on strong authentication (SSH keys) plus aggressive banning (fail2ban) plus minimal attack surface (UFW).

This approach is appropriate for a solo developer working on a small business eCommerce site while traveling internationally.
