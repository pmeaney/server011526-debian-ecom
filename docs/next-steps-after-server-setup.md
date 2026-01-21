# Next Steps After Server Setup

After your Debian server is deployed via Terraform and Nginx Proxy Manager is running, follow these steps to complete your infrastructure setup.

---

## 1. Cloudflare Setup (Optional but Recommended)

Cloudflare provides free DDoS protection, CDN, and hides your real server IP. This is a one-time manual setup.

### Prerequisites
- Server deployed and running ✅
- Nginx Proxy Manager deployed ✅
- A domain name (purchase from any registrar)

### Step 1: Get a Domain

**Purchase a domain from:**
- Namecheap (~$10-15/year)
- Google Domains
- Cloudflare Registrar (cheapest, at-cost pricing)
- Any other registrar

**Recommended naming:**
- Something professional for your guitar marketplace
- Easy to remember and type
- .com is ideal, but .io, .co, .shop also work

### Step 2: Create Cloudflare Account

1. Go to [cloudflare.com](https://cloudflare.com)
2. Sign up for free account
3. Verify email

### Step 3: Add Your Domain to Cloudflare

1. Click "Add a Site"
2. Enter your domain name
3. Select "Free" plan
4. Click "Continue"

### Step 4: Update Nameservers

**Cloudflare will provide you with two nameservers, like:**
- `alice.ns.cloudflare.com`
- `bob.ns.cloudflare.com`

**At your domain registrar:**
1. Log into your registrar account
2. Find DNS or nameserver settings
3. Replace existing nameservers with Cloudflare's nameservers
4. Save changes

**Wait for propagation:** 5 minutes to 24 hours (usually ~30 minutes)

### Step 5: Configure DNS Records in Cloudflare

Once nameservers are active, add DNS records:

| Type | Name | Content | Proxy Status |
|------|------|---------|--------------|
| A | @ | YOUR_SERVER_IP | Proxied (🟠) |
| A | www | YOUR_SERVER_IP | Proxied (🟠) |
| A | forum | YOUR_SERVER_IP | Proxied (🟠) |
| A | blog | YOUR_SERVER_IP | Proxied (🟠) |

**Important:** Click the cloud icon to turn it **orange (Proxied)**. This enables Cloudflare's protection.

**What "Proxied" means:**
- 🟠 Orange Cloud = Traffic routes through Cloudflare (protected, IP hidden)
- ⚪ Gray Cloud = Direct to your server (no protection, IP visible)

### Step 6: Configure SSL/TLS Settings in Cloudflare

1. Go to **SSL/TLS** tab in Cloudflare
2. Set encryption mode to **"Full"** (not "Flexible")
3. Enable **"Always Use HTTPS"**

**Why "Full" mode?**
- User → Cloudflare: HTTPS (encrypted)
- Cloudflare → Your server: HTTPS (encrypted)
- End-to-end encryption

### Step 7: Configure Nginx Proxy Manager

Now configure NPM to route traffic for your domains:

**Access NPM:** `http://YOUR_SERVER_IP:81`

**Add Proxy Hosts (one for each domain):**

**For main site (Vendure eCommerce):**
- Domain Names: `yourdomain.com`, `www.yourdomain.com`
- Scheme: `http`
- Forward Hostname/IP: `vendure` (container name) or Docker bridge IP
- Forward Port: `3000` (or whatever Vendure uses)
- Block Common Exploits: ✅ ON
- Websockets Support: ✅ ON (if needed)
- SSL Tab: Request new SSL certificate, enter email, agree to terms

**For blog (Astro):**
- Domain Names: `blog.yourdomain.com`
- Forward to: `astro:4321`
- Request SSL cert

**For forum (Flarum):**
- Domain Names: `forum.yourdomain.com`
- Forward to: `flarum:8080`
- Request SSL cert

**NPM will automatically:**
- Request Let's Encrypt SSL certificates
- Install them
- Renew them every 90 days
- Redirect HTTP to HTTPS

### Step 8: Test Your Setup

**Check DNS propagation:**
```bash
dig yourdomain.com
```
Should show Cloudflare IPs, not your server IP.

**Visit your domains:**
- `https://yourdomain.com` - Should show your Vendure site
- `https://www.yourdomain.com` - Same
- `https://blog.yourdomain.com` - Your Astro blog
- `https://forum.yourdomain.com` - Your Flarum forum

**Verify SSL:**
- Click the padlock in browser
- Should show valid SSL certificate
- Issued by Let's Encrypt

### How Cloudflare Protects You

**Traffic Flow:**
```
User 
  ↓
Cloudflare (DDoS filtering, bot detection, caching)
  ↓
Your Server (UFW + fail2ban)
  ↓
Nginx Proxy Manager
  ↓
Your Applications (Vendure, Astro, Flarum)
```

**What Cloudflare Blocks:**
- DDoS attacks (absorbs massive traffic)
- Known malicious IPs (threat intelligence database)
- Bot attacks (challenge pages, CAPTCHAs)
- SQL injection attempts (WAF rules)
- Port scanning (your real IP is hidden)

**What Still Reaches Your Server:**
- Legitimate HTTP/HTTPS traffic (already filtered)
- SSH traffic (Cloudflare doesn't proxy SSH - goes direct to your IP)

**SSH Access Remains Direct:**
- SSH (port 22) bypasses Cloudflare
- You can still SSH from cafes, Mexico, anywhere
- Fail2ban protects SSH access

### Cloudflare Free Tier Features

**Included at $0/month:**
- ✅ DDoS protection (unlimited)
- ✅ CDN (caches static assets globally)
- ✅ SSL certificates (automatic)
- ✅ Bot filtering
- ✅ Analytics
- ✅ 5 firewall rules
- ✅ Page rules (3 free)

### Cost Summary

- **Cloudflare:** $0/month (free tier)
- **Domain:** ~$10-15/year (one-time annual cost)
- **SSL Certificates:** $0 (Let's Encrypt via NPM)

**Total:** ~$1.25/month (just the domain)

### Maintenance

**After initial setup:**
- ✅ SSL auto-renews (NPM handles it)
- ✅ Cloudflare protection always active
- ✅ No ongoing configuration needed

**If you rebuild server (new IP):**
1. Update A records in Cloudflare with new IP
2. Takes 30 seconds
3. Everything else stays the same

---

## 2. Deploy Your Applications

With Cloudflare and NPM configured, deploy your containerized applications (Vendure, Astro, Flarum) to the server. Given the setup, it's assumed these are deployed to our terraform-setup server via CICD. 

**Verify applications are accessible:**
- `https://yourdomain.com` - Vendure storefront
- `https://blog.yourdomain.com` - Astro blog
- `https://forum.yourdomain.com` - Flarum forum

---

## 3. Monitoring & Maintenance

### Set Up External Uptime Monitoring

**UptimeRobot (Free):**
1. Sign up at [uptimerobot.com](https://uptimerobot.com)
2. Add monitors for:
   - `https://yourdomain.com` (check every 5 minutes)
   - `https://blog.yourdomain.com`
   - `https://forum.yourdomain.com`
3. Configure email alerts

### Weekly Maintenance Checklist

**Every Sunday (15 minutes):**

```bash
# SSH into server
ssh deb

# Update system packages
sudo apt-get update && sudo apt-get upgrade -y

# Clean up Docker resources.  Careful with this one. Check the docker resources first to see if we have any extra cruft we can prune.
docker system prune -f

# Check disk space
df -h

# Review errors in logs
docker compose logs --since 7d | grep ERROR

# Check fail2ban status
sudo fail2ban-client status sshd
```

### Monthly Checklist

- [ ] Review Cloudflare analytics
- [ ] Check SSL certificate expiry (should auto-renew)
- [ ] Review server resource usage (CPU, RAM)
- [ ] Test backups (if implemented)
- [ ] Review fail2ban banned IPs
- [ ] Update Docker images

---

## 5. Backup Strategy (Recommended)

### Database Backups

**Your PostgreSQL database is already managed by DigitalOcean:**
- Daily automated backups ✅
- Point-in-time recovery ✅
- Stored for 7 days ✅

**Test a restore quarterly** to ensure backups work.

### Application Data Backups

**For Docker volumes:**
```bash
# Backup a volume
docker run --rm -v volume_name:/data -v $(pwd):/backup ubuntu tar czf /backup/backup.tar.gz /data

# Upload to DigitalOcean Spaces or S3
```

**For configuration files:**
```bash
# Backup to git
cd ~/vendure
git add docker-compose.yml
git commit -m "Update config"
git push
```

---

## 6. Security Hardening (Already Done via Cloud-Init)

Your server was automatically hardened during deployment:

- ✅ UFW firewall (only ports 22, 80, 443 allowed)
- ✅ Fail2ban (bans IPs after 3 failed SSH attempts)
- ✅ SSH key-only authentication (passwords disabled)
- ✅ Automatic security updates

**Additional hardening to consider:**
- [ ] Change SSH port from 22 to custom port
- [ ] Set up custom fail2ban jails for applications
- [ ] Enable Cloudflare WAF rules
- [ ] Configure rate limiting in NPM

See `docs/server-security-hardening-guide.md` for details.

---

## Troubleshooting

### Domain Not Resolving

**Check nameservers:**
```bash
dig NS yourdomain.com
```
Should show Cloudflare nameservers.

**If not:** Nameservers not updated at registrar or still propagating (wait up to 24 hours).

### SSL Certificate Errors

**"Certificate Invalid" in browser:**
- Wait 5-10 minutes for Let's Encrypt to issue cert
- Check NPM logs: `docker compose logs nginx-proxy-mgr-011526`
- Verify domain points to your server in Cloudflare DNS

### Site Not Loading

**Check application is running:**
```bash
docker ps
```
Should see your application container.

**Check NPM proxy host configuration:**
- Verify domain name matches
- Verify forward hostname/port is correct
- Check NPM logs for errors

### Can't SSH After Cloudflare Setup

**This is normal** - Cloudflare doesn't proxy SSH.
- SSH goes directly to your server IP
- Use server IP, not domain name: `ssh deb` or `ssh user@SERVER_IP`

---

## Summary

**After completing these steps:**
- ✅ Server is deployed and hardened
- ✅ Cloudflare protecting your site (optional)
- ✅ SSL certificates active and auto-renewing
- ✅ Applications deployed and accessible
- ✅ Monitoring active
- ✅ CI/CD configured (optional)

**Your infrastructure is production-ready.**

Next: Focus on your applications (Vendure configuration, Astro content, Flarum community building).