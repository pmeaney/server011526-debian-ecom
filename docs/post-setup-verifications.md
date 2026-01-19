# Post-Setup Verification Guide

This document walks you through verifying that your Debian server was configured correctly by Terraform and cloud-init. These verifications focus on security configurations to ensure your defense-in-depth strategy is actually in place and working.

**When to use this guide:** After running `terraform apply` and the server has finished its initial boot sequence (typically 2-5 minutes after creation).

---

## Prerequisites: Initial SSH Connection

First, verify you can SSH into your server using the configuration from your setup:

```bash
# From your local machine
ssh deb
```

**What this tests:**
- Your SSH key authentication is working
- The server's IP address is correct in your ~/.ssh/config
- The cloud-init user creation succeeded
- SSH daemon is running and accessible

**Expected result:** You should be logged in as your human user (e.g., `patDevOpsUser@server011526`).

**If this fails:**
- Check that Terraform completed successfully and output the server IP
- Verify your ~/.ssh/config has the correct IP address
- Ensure your SSH private key has correct permissions (`chmod 600 ~/.ssh/id_ed25519_011526_humanuser`)
- Wait a bit longer - cloud-init might still be running

---

## 1. Verify Cloud-Init Completed Successfully

Cloud-init runs asynchronously during first boot. Before checking individual components, confirm that cloud-init actually finished.

### Check Cloud-Init Status

```bash
# Check if cloud-init has finished
sudo cloud-init status --wait

# View detailed cloud-init results
sudo cloud-init status --long
```

**What this does:** The `--wait` flag blocks until cloud-init completes. This is important because if cloud-init is still running, your security configurations might not be in place yet.

**Expected output:**
```
status: done
```

**Why this matters:** If cloud-init failed partway through, you might have UFW configured but not fail2ban, or Docker installed but not UFW enabled. You need to know the full process completed.

**If status shows `error` or `degraded`:**
```bash
# Check cloud-init logs for errors
sudo cat /var/log/cloud-init.log | grep -i error
sudo cat /var/log/cloud-init-output.log | tail -50
```

---

## 2. Verify User Configuration

Cloud-init should have created two users: your human developer account and the GitHub Actions CICD bot account.

### Check User Existence

```bash
# Verify both users exist
id $USER
id ghaCICDBotUser  # Replace with your CICD username if different

# Check user groups
groups $USER
groups ghaCICDBotUser
```

**Expected output for human user:**
```
uid=1001(patDevOpsUser) gid=1001(patDevOpsUser) groups=1001(patDevOpsUser),4(adm),27(sudo),999(docker)
```

**What to look for:**
- User exists (doesn't say "no such user")
- User is in `sudo` group (can run sudo commands)
- User is in `docker` group (can run docker without sudo)

**Expected output for CICD bot:**
```
uid=1002(ghaCICDBotUser) gid=1002(ghaCICDBotUser) groups=1002(ghaCICDBotUser),999(docker)
```

**What to look for:**
- User exists
- User is in `docker` group
- User is NOT in `sudo` group (only has limited sudo access)

### Verify SSH Key Authentication

```bash
# Check that your SSH public key is in authorized_keys
cat ~/.ssh/authorized_keys
```

**Expected output:** Should show your SSH public key (the one you uploaded to 1Password and referenced in your Terraform variables).

**Why this matters:** If your key isn't here, you wouldn't have been able to SSH in. But it's good to verify that cloud-init actually placed it correctly.

### Verify Password Authentication is Disabled

```bash
# Check SSH configuration
sudo grep -i PasswordAuthentication /etc/ssh/sshd_config | grep -v "^#"
```

**Expected output:**
```
PasswordAuthentication no
```

**What this means:** The SSH daemon will reject any password-based login attempts. Only key-based authentication works.

**Why this matters:** This is one of your most important security configurations. Password authentication is vulnerable to brute-force attacks. Even with fail2ban, disabling passwords entirely eliminates an entire class of attacks.

**Test it (optional):**
From another terminal on your laptop (don't close your working SSH session!), try to SSH with password:
```bash
# This should fail
ssh -o PreferredAuthentications=password patDevOpsUser@YOUR_SERVER_IP
```

You should see `Permission denied (publickey)` - this is correct! The server is rejecting password authentication entirely.

---

## 3. Verify Docker Installation

Docker should be installed via the official Docker installation script and both users should be able to use it.

### Check Docker Version

```bash
# Verify Docker is installed
docker --version

# Check Docker daemon is running
sudo systemctl status docker
```

**Expected output for version:**
```
Docker version 25.0.0, build abc1234
```

**Expected output for status:**
```
● docker.service - Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
     Active: active (running) since [timestamp]
```

**What to look for:**
- Recent Docker version (should be 24.x or newer)
- Status shows `active (running)`
- Service is `enabled` (will start on boot)

### Verify Docker Group Membership Works

```bash
# Run docker command without sudo (tests group membership)
docker ps

# This should work without prompting for password
```

**Expected output:**
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

(Empty list is fine - you haven't deployed containers yet)

**If this fails with permission denied:**
Your user wasn't added to the docker group correctly. You can add yourself manually:
```bash
sudo usermod -aG docker $USER
# Then log out and back in for group changes to take effect
```

**Why this matters:** Without docker group membership, you'd need to use `sudo docker` for every command, which is annoying and reduces security (sudo should be used sparingly).

---

## 4. Verify UFW Firewall Configuration

UFW is your second layer of firewall defense (after DigitalOcean's cloud firewall). It should be enabled and configured to only allow ports 22, 80, and 443.

### Check UFW Status

```bash
# View detailed UFW status
sudo ufw status verbose
```

**Expected output:**
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                ALLOW IN    Anywhere (v6)
443/tcp (v6)               ALLOW IN    Anywhere (v6)
```

**Critical things to verify:**
- `Status: active` - UFW is running and enforcing rules
- `Default: deny (incoming)` - Everything not explicitly allowed is blocked
- `Default: allow (outgoing)` - Your server can make outbound connections (for updates, API calls, etc.)
- Only ports 22, 80, 443 are allowed inbound
- Rules exist for both IPv4 and IPv6

**Why this matters:** This is what stopped the PayloadCMS attack on port 3000. Any traffic to ports other than 22, 80, 443 is dropped at the kernel level before it can reach your applications.

### Test UFW is Actually Blocking

From your local machine (not SSH'd into the server), try to connect to a port that should be blocked:

```bash
# From your laptop - this should timeout/fail
telnet YOUR_SERVER_IP 3000
# Or
nc -zv YOUR_SERVER_IP 3000
```

**Expected result:** Connection timeout or "Connection refused" after a delay. The connection should NOT succeed.

**Why this works:** UFW is dropping packets destined for port 3000, so your connection attempt gets no response. This is exactly what happens when attackers try to hit unexpected ports.

### Check UFW Logs (Optional)

UFW logs blocked packets to syslog. You can see what's being blocked:

```bash
# View recent UFW blocks
sudo grep UFW /var/log/syslog | tail -20

# Count blocks by port
sudo grep UFW /var/log/syslog | grep -oP 'DPT=\K[0-9]+' | sort | uniq -c | sort -rn | head -10
```

**What you might see:** Lots of attempts on common ports that malware and botnets scan for (3000, 5432, 8080, etc.). This is normal internet background radiation.

---

## 5. Verify Fail2ban Configuration

Fail2ban monitors SSH authentication attempts and bans IPs that fail too many times. This is your primary defense against SSH brute-force attacks.

### Check Fail2ban Status

```bash
# Verify fail2ban service is running
sudo systemctl status fail2ban

# Check SSH jail status
sudo fail2ban-client status sshd
```

**Expected output for service status:**
```
● fail2ban.service - Fail2Ban Service
     Loaded: loaded (/lib/systemd/system/fail2ban.service; enabled)
     Active: active (running) since [timestamp]
```

**Expected output for jail status:**
```
Status for the jail: sshd
|- Filter
|  |- Currently failed:	0
|  |- Total failed:	0
|  `- File list:	/var/log/auth.log
`- Actions
   |- Currently banned:	0
   |- Total banned:	0
   `- Banned IP list:
```

**What to look for:**
- Service is `active (running)`
- SSH jail (sshd) is active and monitoring `/var/log/auth.log`
- Shows counts of failed attempts and banned IPs

**Why these numbers might be zero:** If you just set up the server, no one has tried to attack it yet. Give it a few hours or days, and you'll start seeing failed attempts and bans as bots find your server.

### Check Fail2ban Configuration

```bash
# Verify SSH jail configuration
sudo fail2ban-client get sshd maxretry
sudo fail2ban-client get sshd bantime
sudo fail2ban-client get sshd findtime
```

**Expected output:**
```
3        (maxretry - ban after 3 failures)
600      (bantime - ban for 600 seconds / 10 minutes)
600      (findtime - 3 failures within 600 seconds triggers ban)
```

**What this means:** If someone fails SSH authentication 3 times within 10 minutes, their IP gets banned for 10 minutes. This effectively stops brute-force attacks while not permanently blocking legitimate users who make mistakes.

### View Fail2ban Logs

```bash
# See recent fail2ban actions
sudo journalctl -u fail2ban -n 50 --no-pager

# Or check fail2ban's own log file
sudo tail -50 /var/log/fail2ban.log
```

**What to look for:**
- Lines showing "Jail 'sshd' started" (confirms jail is active)
- Eventually you'll see lines like "Ban 203.0.113.45" when attackers hit your server

### Test Fail2ban (Optional - Advanced)

You can test that fail2ban actually works by intentionally failing SSH attempts from another machine. **WARNING:** This will temporarily ban the testing IP address.

```bash
# From a machine you can temporarily lose SSH access from (NOT your main laptop!)
# Try to SSH with wrong credentials 3 times
ssh wronguser@YOUR_SERVER_IP
# Type wrong password or Ctrl+C
# Repeat 2 more times quickly
```

After the third attempt, that IP should be banned. Check with:
```bash
# On your server (from your main SSH session)
sudo fail2ban-client status sshd
```

You should see the testing IP in the "Banned IP list". After 10 minutes, it will be automatically unbanned.

---

## 6. Verify System Updates

Your cloud-init configuration includes `package_update: true` and `package_upgrade: true`, which should have updated all packages during initial setup.

### Check Update Status

```bash
# Check if updates are available
sudo apt-get update
sudo apt-get upgrade --dry-run
```

**Expected output:** "0 upgraded, 0 newly installed" - meaning everything is already up to date from the cloud-init process.

**If updates are available:** This is fine - new updates may have been released since your cloud-init ran. You can apply them:
```bash
sudo apt-get upgrade -y
```

### Verify Automatic Security Updates (Optional Future Enhancement)

Debian doesn't enable automatic security updates by default. You might want to configure this later:

```bash
# Check if unattended-upgrades is installed
dpkg -l | grep unattended-upgrades
```

**Current expected result:** Not installed (this is fine for now, but you might add it to your cloud-init later).

---

## 7. Verify Package Installations

Check that all the packages specified in your cloud-init were actually installed.

```bash
# Check for specific packages
dpkg -l | grep -E 'zsh|git|make|rsync|ufw|fail2ban'
```

**Expected output:** Should show all these packages as installed with status `ii` (installed and ok).

**Why this matters:** If cloud-init failed to install a package, you might have an incomplete security configuration. For example, if fail2ban isn't installed, that entire security layer is missing.

---

## 8. Verify DigitalOcean Cloud Firewall (From Your Laptop)

The cloud firewall operates at DigitalOcean's infrastructure level, before traffic even reaches your server. You need to test this from outside the server.

### Test Cloud Firewall from Your Laptop

**IMPORTANT:** Run these commands from your LOCAL MACHINE, not from SSH'd into your server.

```bash
# Test that SSH is allowed (should succeed)
ssh -o ConnectTimeout=5 YOUR_USERNAME@YOUR_SERVER_IP echo "SSH works"

# Test that blocked ports fail (should timeout)
nc -zv -w 5 YOUR_SERVER_IP 3000
nc -zv -w 5 YOUR_SERVER_IP 5432
nc -zv -w 5 YOUR_SERVER_IP 8080
```

**Expected results:**
- SSH command succeeds and prints "SSH works"
- Port 3000 (PayloadCMS): Connection times out
- Port 5432 (PostgreSQL): Connection times out  
- Port 8080 (alternative web): Connection times out

**Why this test matters:** This confirms your cloud firewall is blocking unexpected ports before they even reach your server. If these ports were open, UFW would catch them (Layer 2), but the cloud firewall (Layer 1) is your first line of defense.

### Check Cloud Firewall in DigitalOcean Dashboard (Optional)

You can also verify through the web UI:

1. Log into DigitalOcean
2. Navigate to Networking → Firewalls
3. Click on your firewall (should be named "vendure-ecommerce-firewall")
4. Verify inbound rules show only ports 22, 80, 443 allowed
5. Verify outbound rules allow all necessary traffic

---

## 9. Verify Kernel Hardening Settings

Your cloud-init configuration applies kernel security parameters via sysctl. These settings protect against various network-level attacks.

### Check Kernel Security Parameters

```bash
# Check SYN cookie protection (DDoS defense)
sudo sysctl net.ipv4.tcp_syncookies

# Check IP spoofing protection
sudo sysctl net.ipv4.conf.all.rp_filter
sudo sysctl net.ipv4.conf.default.rp_filter

# Check ICMP redirect protection
sudo sysctl net.ipv4.conf.all.accept_redirects
sudo sysctl net.ipv4.conf.all.send_redirects

# Check source routing protection
sudo sysctl net.ipv4.conf.all.accept_source_route

# Check martian packet logging
sudo sysctl net.ipv4.conf.all.log_martians
```

**Expected results:**
```
net.ipv4.tcp_syncookies = 1                          (enabled - DDoS protection)
net.ipv4.conf.all.rp_filter = 1                      (enabled - anti-spoofing)
net.ipv4.conf.default.rp_filter = 1                  (enabled - anti-spoofing)
net.ipv4.conf.all.accept_redirects = 0               (disabled - MITM protection)
net.ipv4.conf.all.send_redirects = 0                 (disabled - we're not a router)
net.ipv4.conf.all.accept_source_route = 0            (disabled - firewall bypass protection)
net.ipv4.conf.all.log_martians = 1                   (enabled - logs suspicious packets)
```

**What these settings do:**
- **SYN cookies:** Protects against SYN flood DDoS attacks by using stateless connection tracking when under attack
- **Reverse path filtering:** Blocks packets with spoofed source IP addresses
- **ICMP redirect protection:** Prevents man-in-the-middle attacks via fake routing updates
- **Source route protection:** Prevents attackers from specifying packet paths to bypass firewalls
- **Martian logging:** Records packets with impossible source addresses for monitoring

### Verify Kernel Config File Exists

```bash
# Check that the hardening config file was created
sudo cat /etc/sysctl.d/99-hardening.conf
```

**Expected output:** Should show all the kernel parameters from your cloud-init configuration with comments explaining each one.

**Why this matters:** These kernel-level settings provide protection that operates below the application layer. Even if an attacker bypasses application security, these kernel protections are still in place.

### Check for Martian Packet Logs (Attack Visibility)

```bash
# Check if any suspicious packets have been logged
sudo grep martian /var/log/syslog | tail -20
```

**What you might see:** Log entries showing packets with spoofed source addresses that were blocked. This gives you visibility into attack attempts.

**Example log entry:**
```
Jan 19 14:23:45 server011526 kernel: martian source 192.168.1.1 from 203.0.113.45, on dev eth0
```

This would indicate an attacker tried to send packets claiming to be from a private IP address (192.168.1.1) from a public internet address (203.0.113.45) - a clear spoofing attempt that was blocked.

**If you don't see any martian logs yet:** This is normal for a fresh server. Spoofing attacks are less common than port scans. You'll likely see some within the first few weeks.

---

## 10. Check Running Services

Verify that only necessary services are running on your fresh server.

```bash
# List all enabled systemd services
systemctl list-unit-files --state=enabled --type=service | grep enabled

# List all currently running services
systemctl list-units --type=service --state=running
```

**What you should see:**
- `ssh.service` - SSH daemon (necessary for remote access)
- `docker.service` - Docker daemon (necessary for containers)
- `ufw.service` - Firewall service (necessary for security)
- `fail2ban.service` - Intrusion prevention (necessary for security)
- Standard system services (systemd-*, networking, etc.)

**What you should NOT see:**
- Web servers running directly (Apache, nginx) - these should only run in containers
- Database servers running directly (MySQL, PostgreSQL) - these should only run in containers
- Unnecessary services like telnet, FTP, etc.

**Why minimal services matter:** Every service that's running is potential attack surface. By running only essential services on the host and putting everything else in containers, you reduce the number of entry points an attacker could exploit.

---

## 11. Security Verification Summary

Create a simple script to run all these checks at once. Save this as `verify-security.sh`:

```bash
#!/bin/bash

echo "==================================="
echo "Security Configuration Verification"
echo "==================================="
echo ""

echo "1. Cloud-init status:"
sudo cloud-init status --wait
echo ""

echo "2. User groups:"
groups $USER
echo ""

echo "3. Docker status:"
systemctl is-active docker
docker ps > /dev/null 2>&1 && echo "Docker accessible without sudo: YES" || echo "Docker accessible without sudo: NO"
echo ""

echo "4. UFW status:"
sudo ufw status | head -1
echo ""

echo "5. Fail2ban status:"
systemctl is-active fail2ban
sudo fail2ban-client status sshd | grep "Currently banned"
echo ""

echo "6. SSH password authentication:"
sudo grep "^PasswordAuthentication" /etc/ssh/sshd_config
echo ""

echo "7. Kernel hardening - SYN cookies:"
sudo sysctl net.ipv4.tcp_syncookies
echo ""

echo "8. Kernel hardening - Reverse path filter:"
sudo sysctl net.ipv4.conf.all.rp_filter
echo ""

echo "9. Open ports (should only be 22, 80, 443):"
sudo ss -tulpn | grep LISTEN | grep -E ":(22|80|443|3000|5432|8080)" | awk '{print $5}' | cut -d: -f2 | sort -u
echo ""

echo "10. Recent UFW blocks (last 5):"
sudo grep UFW /var/log/syslog | tail -5
echo ""

echo "==================================="
echo "Verification complete!"
echo "==================================="
```

Make it executable and run it:

```bash
chmod +x verify-security.sh
./verify-security.sh
```

This gives you a quick overview of your security posture in one command.

---

## 12. What to Do If Verifications Fail

If any of these verifications fail, here's your troubleshooting workflow:

### Cloud-init failed or is degraded

```bash
# Check detailed logs
sudo cat /var/log/cloud-init-output.log | less
sudo journalctl -u cloud-init -n 100

# Look for specific errors
sudo grep -i error /var/log/cloud-init.log
```

**Common issues:**
- Network problems during first boot (retry the installation)
- Syntax errors in cloud-init YAML (check your tf-cloud-config.yml)
- Package installation failures (temporary repo issues)

### UFW is not active

```bash
# Enable UFW manually
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

### Fail2ban is not running

```bash
# Check fail2ban logs for errors
sudo journalctl -u fail2ban -n 50

# Restart fail2ban
sudo systemctl restart fail2ban
sudo systemctl status fail2ban
```

### Docker group membership not working

```bash
# Add yourself to docker group manually
sudo usermod -aG docker $USER

# Log out and back in
exit
ssh deb

# Verify
docker ps
```

### Kernel hardening settings not applied

```bash
# Apply kernel hardening manually
sudo sysctl -p /etc/sysctl.d/99-hardening.conf

# Verify settings took effect
sudo sysctl net.ipv4.tcp_syncookies
sudo sysctl net.ipv4.conf.all.rp_filter
```

---

## 13. Ongoing Monitoring Checklist

After your initial verification, you should periodically check security status. Create a weekly or monthly checklist:

**Weekly:**
- [ ] Check fail2ban banned IPs: `sudo fail2ban-client status sshd`
- [ ] Review UFW blocked attempts: `sudo grep UFW /var/log/syslog | tail -50`
- [ ] Check martian packet logs: `sudo grep martian /var/log/syslog | tail -20`
- [ ] Check for available updates: `sudo apt-get update && sudo apt-get upgrade --dry-run`
- [ ] Verify Docker containers are running: `docker ps`

**Monthly:**
- [ ] Review authentication logs: `sudo grep -i failed /var/log/auth.log | tail -100`
- [ ] Check disk space: `df -h`
- [ ] Verify backups are working (when you implement them)
- [ ] Review running services: `systemctl list-units --type=service --state=running`
- [ ] Verify kernel hardening still applied: `sudo sysctl net.ipv4.tcp_syncookies`

---

## 14. Success Criteria

Your server is properly secured when all of the following are true:

✅ Cloud-init status shows "done"  
✅ SSH password authentication is disabled  
✅ UFW is active with only ports 22, 80, 443 allowed  
✅ Fail2ban is running and monitoring SSH  
✅ Docker is installed and accessible without sudo  
✅ Both user accounts exist with correct group memberships  
✅ Kernel hardening settings are applied (SYN cookies, rp_filter, etc.)  
✅ System packages are up to date  
✅ Outbound connectivity works (DNS, HTTPS)  
✅ Cloud firewall blocks unexpected ports (verified from laptop)  
✅ Only essential services are running  

If all these criteria are met, your defense-in-depth security strategy is fully operational and your server is ready for deploying applications.

---

## Notes on Security Posture

After completing these verifications, you have:

**Layer 1 - Cloud Firewall:** Blocking unexpected ports at DigitalOcean's infrastructure  
**Layer 2 - UFW:** Blocking unexpected ports at the kernel level  
**Layer 3 - Fail2ban:** Dynamically banning brute-force attackers  
**Layer 4 - SSH Keys Only:** Eliminating password-based attacks entirely  
**Layer 5 - Kernel Hardening:** Network-level protections against DDoS, spoofing, and MITM attacks  
**Layer 6 - Minimal Services:** Reducing attack surface  
**Layer 7 - Updated Packages:** Having latest security patches  

This puts you in the top tier of small business server security. Most servers on the internet don't have even half of these protections in place.

The verification process you've just completed isn't just a checklist - it's building your understanding of how each security layer works and how to confirm it's functioning correctly. This knowledge will serve you well as you maintain and evolve your infrastructure.
