# Setup Workflow - server011526-debian-ecom

This guide walks through the complete server setup process from scratch.

## Prerequisites

Before starting, ensure you have these tools installed:

- [ ] **1Password** installed and authenticated (`op signin`)
- [ ] **GitHub CLI** installed (`gh --version`)
- [ ] **DigitalOcean CLI** installed (`doctl version`)
- [ ] **Terraform** installed (`terraform version`)

---

## Phase 0: 1Password Setup for the Project

**What this does:** Creates the organizational structure in 1Password where all your secrets and configuration will be stored. Think of this as setting up a filing cabinet before adding documents.

### 0.1 Create a Vault (if you don't have one)

1. Open 1Password application
2. Create a new vault or use an existing one
3. Example name: `Z_Tech_ClicksAndCodes`

**Note:** A vault is like a folder that contains multiple items. You might reuse this vault for other tech projects.

### 0.2 Create a Secure Note Item

1. In your vault, create a new **Secure Note** item
2. Title it: `server011526-debian-ecom`
3. This item will hold all configuration values for this specific project

**Note:** This single item will eventually contain:
- API tokens (DigitalOcean, GitHub)
- SSH public keys
- Linux usernames
- Server name
- Server IP address (added automatically by Terraform later)

---

## Phase 1: Manual Token Creation

**What this does:** Creates API tokens that give command-line tools permission to access DigitalOcean and GitHub on your behalf. These must be created manually through web interfaces (they can't be generated via CLI for security reasons).

These tokens cannot be created via CLI - must be done manually through web interfaces.

### 1.1 Create DigitalOcean Token

**What this does:** Creates an API token that allows Terraform and the `doctl` CLI tool to create and manage servers on your behalf.

1. Log into DigitalOcean Dashboard
2. Navigate to: **API → Tokens/Keys → Generate New Token**
3. Token settings:
   - Name: `DOToken_FA_011526` (FA = Full Access)
   - Scopes: **Full Access** (read + write)
   - Expiration: Choose appropriate timeframe
4. **Copy the token immediately** - you won't see it again
5. Store in 1Password:
   - Open your `server011526-debian-ecom` item in 1Password
   - Add field: Type = `Password`, Label = `DOToken_FA_011526`
   - Paste token value

**Important:** The token is only shown once. If you lose it, you'll need to create a new one.

### 1.2 Create GitHub Personal Access Token

**What this does:** Creates a token that allows the `gh` CLI tool to upload SSH keys to your GitHub account and enables GitHub Actions to deploy to your server later.

1. Log into GitHub
2. Navigate to: **Settings → Developer Settings → Personal Access Tokens → Tokens (classic) → Generate new token**
3. Token settings:
   - Note: `GHPATCICD_RpoWkflo_WRDpckgs_011526`
   - Expiration: Choose appropriate timeframe
   - Scopes (check these boxes):
     - ✅ `repo` (Full control of private repositories)
     - ✅ `workflow` (Update GitHub Action workflows)
     - ✅ `write:packages` (Upload packages)
     - ✅ `read:packages` (Download packages)
     - ✅ `delete:packages` (Delete packages)
     - ✅ `read:org` (Read org and team membership)
     - ✅ `admin:public_key` (Full control of user public keys)
4. **Copy the token immediately** - you won't see it again
5. Store in 1Password:
   - Open your `server011526-debian-ecom` item
   - Add field: Type = `Password`, Label = `GHPATCICD_RpoWkflo_WRDpckgs_011526`
   - Paste token value

**Note:** The `admin:public_key` scope is what allows the CLI to automatically upload SSH keys to your GitHub account in the next phase.

---

## Phase 2: SSH Key Setup

**What this does:** Creates two sets of SSH keys (think of them like digital keys to your server). One for you (human user) to manually access the server, and one for GitHub Actions (CICD bot) to automatically deploy code.

**Why two keys?** 
- Security: If the CICD key is compromised, you can revoke it without losing your own access
- Permissions: The CICD bot has limited sudo privileges (only Docker commands)
- Auditability: You can see which actions were done by humans vs automation

You'll create **two SSH key pairs**:
1. **Human user key** - for your manual server access from your laptop
2. **CICD bot key** - for GitHub Actions automated deployments

Each key pair consists of:
- **Private key** - stays on your laptop (never share this!)
- **Public key** - gets uploaded to DigitalOcean, GitHub, and stored in 1Password

### 2.1 Set Variables for Key Generation

**What this does:** Creates temporary shell variables to make the commands below easier to copy/paste. These are just shortcuts - the actual SSH keys will be created in the next steps and automatically uploaded to 1Password.

Copy and paste this block to set your email and key names:

```bash
export EMAIL=patrick.wm.meaney@gmail.com
export SSH_KEY_NAME_HUMAN=id_ed25519_011526_humanuser
export SSH_KEY_NAME_CICD=id_ed25519_011526_cicd
```

**Note:** These variables only last for this terminal session. If you close the terminal, you'll need to re-export them.

### 2.2 Set 1Password Variables

**What this does:** Points to the vault and item you created in Phase 0. These variables tell the upcoming commands where to store and retrieve secrets from 1Password.

```bash
export VAULT_1P=Z_Tech_ClicksAndCodes
export ITEM_1P="server011526-debian-ecom"
export FIELD_1P_DO_TOKEN=DOToken_FA_011526
export FIELD_1P_GH_TOKEN=GHPATCICD_RpoWkflo_WRDpckgs_011526
```

**Note:** These match the names you used in Phase 0 and Phase 1. If you used different names, update them here.

### 2.3 Generate Human User SSH Key

**What this does:** Creates a new SSH key pair specifically for you to access the server. The `-N ""` flag means no password protection - the key file itself is the security.

```bash
# Generate key (no password - SSH keys themselves provide security)
ssh-keygen -t ed25519 -C "${EMAIL}" -f ~/.ssh/${SSH_KEY_NAME_HUMAN} -N ""
```

**Why no password?** SSH keys are already very secure. Adding a password would mean typing it every time you connect. Since the private key never leaves your laptop, the key file itself is sufficient protection.

**Verify:** Check that files were created
```bash
ls -la ~/.ssh/${SSH_KEY_NAME_HUMAN}*
```

You should see:
- `id_ed25519_011526_humanuser` (private key - NEVER share this)
- `id_ed25519_011526_humanuser.pub` (public key - safe to share)

### 2.4 Add Human Key to SSH Agent

**What this does:** Loads your private key into the SSH agent (a background program that holds your keys in memory). This means you won't need to specify `-i ~/.ssh/keyname` every time you SSH - the agent automatically offers the right key.

```bash
ssh-add ~/.ssh/${SSH_KEY_NAME_HUMAN}
```

**Verify:** List keys in agent
```bash
ssh-add -l
```

You should see your key listed with its fingerprint and comment (your email).

### 2.5 Upload Human Key to 1Password

**What this does:** Stores your public SSH key in 1Password for backup and reference. This is NOT used for authentication - it's just for your records and to make the key available if you need to reference it later.

```bash
op item edit "$ITEM_1P" --vault "$VAULT_1P" \
  "${SSH_KEY_NAME_HUMAN}[text]=$(cat ~/.ssh/${SSH_KEY_NAME_HUMAN}.pub)"
```

**Verify:** Retrieve key from 1Password
```bash
op item get "${ITEM_1P}" --vault "${VAULT_1P}" --fields label=${SSH_KEY_NAME_HUMAN}
```

You should see the public key content (starts with `ssh-ed25519`).

### 2.6 Upload Human Key to GitHub

**What this does:** Adds your public SSH key to your GitHub account. This allows you to git push/pull via SSH and, more importantly, allows the GitHub CLI tools to recognize you.

```bash
# Authenticate with GitHub using your PAT token
echo "$(op item get "${ITEM_1P}" --vault "${VAULT_1P}" --field "${FIELD_1P_GH_TOKEN}")" | gh auth login --with-token

# Upload SSH key to GitHub
gh ssh-key add ~/.ssh/${SSH_KEY_NAME_HUMAN}.pub -t "${SSH_KEY_NAME_HUMAN}"
```

**What just happened?**
1. First command: Logged into GitHub CLI using the token you created in Phase 1
2. Second command: Uploaded your public key to your GitHub account

**Verify:** List GitHub SSH keys
```bash
gh ssh-key list
```

You should see your key listed with the title `id_ed25519_011526_humanuser`.

### 2.7 Upload Human Key to DigitalOcean

**What this does:** Adds your public SSH key to your DigitalOcean account. When Terraform creates a server in the next phase, it will automatically install this key, allowing you to SSH in immediately.

```bash
# Authenticate with DigitalOcean using your token
doctl auth init --context default --access-token "$(op item get "${ITEM_1P}" --vault "${VAULT_1P}" --field "${FIELD_1P_DO_TOKEN}")"

# Upload SSH key to DigitalOcean
doctl compute ssh-key create "${SSH_KEY_NAME_HUMAN}" \
  --public-key "$(cat ~/.ssh/${SSH_KEY_NAME_HUMAN}.pub)"
```

**What just happened?**
1. First command: Logged into DigitalOcean CLI using the token you created in Phase 1
2. Second command: Uploaded your public key to your DigitalOcean account

**Verify:** List DigitalOcean SSH keys
```bash
doctl compute ssh-key list
```

You should see your key with the name `id_ed25519_011526_humanuser`.

### 2.8 Add Human Key to SSH Config

**What this does:** Creates a shortcut in your SSH configuration so you can type `ssh deb` instead of `ssh patDevOpsUser@64.23.153.252` every time. This makes connecting to your server much faster and easier.

This makes SSH easier - you can use `ssh deb` instead of `ssh user@ip`

```bash
cat << EOF >> ~/.ssh/config

# server011526-debian-ecom - Human User
Host deb
    User patDevOpsUser
    Hostname PLACEHOLDER_IP
    IdentityFile ~/.ssh/${SSH_KEY_NAME_HUMAN}
    AddKeysToAgent yes
    
EOF
```

**Note:** The `Hostname PLACEHOLDER_IP` will be updated after Terraform creates the server in Phase 5. For now, it's just a placeholder.

**What each line means:**
- `Host deb` - The shortcut name you'll use
- `User patDevOpsUser` - The username on the server (created by Terraform)
- `Hostname PLACEHOLDER_IP` - Server IP (you'll update this later)
- `IdentityFile` - Which private key to use for this connection
- `AddKeysToAgent yes` - Automatically add this key to SSH agent when used

---

### 2.9 Generate CICD Bot SSH Key

**What this does:** Creates a second SSH key pair specifically for GitHub Actions (your automation). This key will eventually be added to GitHub repository secrets, allowing automated deployments without storing your personal key in GitHub.

**Why a separate key?** 
- Security: If compromised, you can revoke it without affecting your personal access
- Least privilege: This key will have limited sudo permissions (only Docker commands)
- Auditability: Server logs will show which actions were automated vs manual

```bash
# Generate key (no password)
ssh-keygen -t ed25519 -C "${EMAIL}" -f ~/.ssh/${SSH_KEY_NAME_CICD} -N ""
```

**Verify:** Check that files were created
```bash
ls -la ~/.ssh/${SSH_KEY_NAME_CICD}*
```

You should see:
- `id_ed25519_011526_cicd` (private key - this will go to GitHub secrets later)
- `id_ed25519_011526_cicd.pub` (public key - goes to DO, GH, 1Password now)

### 2.10 Add CICD Key to SSH Agent

**What this does:** Loads the CICD key into your SSH agent. This is mainly for testing - the actual GitHub Actions runner will use this key differently (from repository secrets).

```bash
ssh-add ~/.ssh/${SSH_KEY_NAME_CICD}
```

### 2.11 Upload CICD Key to 1Password

**What this does:** Stores the CICD public key in 1Password for backup and reference.

```bash
op item edit "$ITEM_1P" --vault "$VAULT_1P" \
  "${SSH_KEY_NAME_CICD}[text]=$(cat ~/.ssh/${SSH_KEY_NAME_CICD}.pub)"
```

**Verify:**
```bash
op item get "${ITEM_1P}" --vault "${VAULT_1P}" --fields label=${SSH_KEY_NAME_CICD}
```

### 2.12 Upload CICD Key to GitHub

**What this does:** Adds the CICD public key to your GitHub account. Later, when you set up a project repository, you'll add the private key to that repository's secrets.

```bash
gh ssh-key add ~/.ssh/${SSH_KEY_NAME_CICD}.pub -t "${SSH_KEY_NAME_CICD}"
```

### 2.13 Upload CICD Key to DigitalOcean

**What this does:** Adds the CICD public key to DigitalOcean. When Terraform creates the server, it will install this key for the `ghaCICDBotUser` account, allowing GitHub Actions to SSH in and deploy.

```bash
doctl compute ssh-key create "${SSH_KEY_NAME_CICD}" \
  --public-key "$(cat ~/.ssh/${SSH_KEY_NAME_CICD}.pub)"
```

**Verify all keys are uploaded:**
```bash
gh ssh-key list
doctl compute ssh-key list
```

You should see both keys (human and CICD) listed in both services.

---

## Phase 3: Add Additional 1Password Fields

**What this does:** Adds the remaining configuration values to your 1Password item. Terraform will read these values in the next phase to configure your server (creating users, naming the server, etc.).

**Why manually?** These are simple text values that don't need automation. It's faster to add them through the 1Password interface than to script it.

In 1Password, open your `server011526-debian-ecom` item and add these fields:

| Field Label | Type | Value | Purpose |
|-------------|------|-------|---------|
| `LINUX_HUMAN_USERNAME` | text | `patDevOpsUser` | Your SSH username on the server |
| `LINUX_BOTCICDGHA_USERNAME` | text | `ghaCICDBotUser` | GitHub Actions bot username |
| `LINUX_SERVER_NAME` | text | `server011526-debian-ecom` | Name shown in DigitalOcean dashboard |
| `VAULT_1P` | text | `Z_Tech_ClicksAndCodes` | Your vault name (for Terraform to write back IP) |
| `LINUX_SERVER_IPADDRESS` | text | *(leave empty)* | Terraform will populate this automatically |

**Note:** The `LINUX_SERVER_IPADDRESS` field should be created but left empty. Terraform will automatically write the server's IP address here after creating the droplet.

---

## Phase 4: Export Environment Variables

**What this does:** Pulls all your configuration from 1Password and exports it as environment variables. Terraform reads these variables to know what to create (server name, usernames, SSH keys, etc.).

**Why environment variables?** This keeps secrets out of your code. The Terraform files contain no passwords or tokens - everything comes from your secure 1Password vault.

**Important:** These variables only exist in your current terminal session. If you close the terminal, you'll need to export them again.

Terraform reads configuration from environment variables. Export them from 1Password:

```bash
# Set item name
ITEM_1P="server011526-debian-ecom"

# Export DigitalOcean token (required by DO provider)
export DIGITALOCEAN_ACCESS_TOKEN=$(op item get ${ITEM_1P} --fields label=DOToken_FA_011526)

# Export Terraform variables (TF_VAR_ prefix required)
export TF_VAR_LINUX_SERVER_NAME=$(op item get ${ITEM_1P} --fields label=LINUX_SERVER_NAME)
export TF_VAR_LINUX_HUMAN_USERNAME=$(op item get ${ITEM_1P} --fields label=LINUX_HUMAN_USERNAME)
export TF_VAR_LINUX_HUMAN_SSHKEY=$(op item get ${ITEM_1P} --fields label=id_ed25519_011526_humanuser)
export TF_VAR_LINUX_BOTCICDGHA_USERNAME=$(op item get ${ITEM_1P} --fields label=LINUX_BOTCICDGHA_USERNAME)
export TF_VAR_LINUX_CICDGHA_SSHKEY=$(op item get ${ITEM_1P} --fields label=id_ed25519_011526_cicd)
export TF_VAR_VAULT_1P=$(op item get ${ITEM_1P} --fields label=VAULT_1P)
export TF_VAR_ITEM_1P=${ITEM_1P}
```

**What's the difference between variables?**
- `DIGITALOCEAN_ACCESS_TOKEN` - DigitalOcean provider specifically looks for this exact name
- `TF_VAR_*` - These are Terraform variables defined in your .tf file. The `TF_VAR_` prefix tells Terraform to use them.

**Verify variables are set:**
```bash
echo $DIGITALOCEAN_ACCESS_TOKEN
echo $TF_VAR_LINUX_SERVER_NAME
echo $TF_VAR_LINUX_HUMAN_USERNAME
```

You should see your token and configuration values printed. If they're empty, the export commands didn't work.

---

## Phase 5: Terraform Execution

**What this does:** Uses Terraform to automatically create and configure your DigitalOcean server. This is infrastructure-as-code - the server setup is defined in files, making it reproducible and documented.

**What Terraform will create:**
- 1 DigitalOcean Droplet (Debian 12, 2 vCPU, 4GB RAM)
- 2 user accounts (`patDevOpsUser` and `ghaCICDBotUser`)
- SSH keys installed for both users
- Docker pre-installed
- Password authentication disabled (SSH keys only)

### 5.1 Navigate to Terraform Directory

```bash
cd /path/to/server011526-debian-ecom
```

Replace `/path/to/` with wherever you've cloned or created this project.

### 5.2 Initialize Terraform

**What this does:** Downloads the DigitalOcean provider plugin and prepares Terraform's working directory. This only needs to be run once per project (or when you add new providers).

```bash
terraform init
```

You should see: `Terraform has been successfully initialized!`

### 5.3 Review Terraform Plan

**What this does:** Shows you exactly what Terraform will create WITHOUT actually creating it. This is a safety check - always review the plan before applying.

```bash
terraform plan
```

Review the output carefully. You should see:
- **+ digitalocean_droplet.debian_server** - The server to be created
- Details about size, region, image, user_data (cloud-init configuration)
- **+ 1 to add, 0 to change, 0 to destroy**

**If something looks wrong, STOP HERE.** Don't proceed to apply until the plan looks correct.

### 5.4 Apply Terraform Configuration

**What this does:** Actually creates the infrastructure. This is the point of no return - it will charge your DigitalOcean account and create real resources.

```bash
terraform apply
```

Type `yes` when prompted.

**What happens next (takes 2-5 minutes):**
1. ✅ Terraform creates a Debian droplet on DigitalOcean
2. ✅ Cloud-init runs on first boot:
   - Creates `patDevOpsUser` with your SSH key
   - Creates `ghaCICDBotUser` with CICD SSH key
   - Installs Docker
   - Disables password authentication
   - Adds users to docker group
3. ✅ Terraform captures the server IP address
4. ✅ Terraform runs 1Password CLI to store IP in your 1Password item

**Watch for:**
- `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`
- The server IP address should be displayed in the output

**Wait for completion** - don't interrupt this process!

### 5.5 Retrieve Server IP

**What this does:** Gets the server's IP address so you can connect to it. Terraform automatically stored it in 1Password, but you can also get it from Terraform's output.

```bash
# From 1Password
export SERVER_IP=$(op item get ${ITEM_1P} --fields label=LINUX_SERVER_IPADDRESS)
echo $SERVER_IP

# Or from Terraform output
terraform output
```

Copy this IP address - you'll need it for the next step.

### 5.6 Update SSH Config

**What this does:** Replaces the placeholder IP in your SSH config with the real server IP, allowing you to use `ssh deb` to connect.

Edit `~/.ssh/config` and replace `PLACEHOLDER_IP` with your actual server IP:

```bash
# Before:
Hostname PLACEHOLDER_IP

# After (example):
Hostname 64.23.153.252
```

Or do it with a command:
```bash
# Replace PLACEHOLDER_IP with your actual IP
sed -i '' 's/PLACEHOLDER_IP/64.23.153.252/' ~/.ssh/config
```

**Note:** On Linux, remove the `''` after `-i`

---

## Phase 6: Verify Server Access

**What this does:** Confirms that everything worked - you can SSH into your new server, Docker is installed, and both user accounts work correctly.

### 6.1 Test SSH Connection

**What this does:** Attempts to connect to your server. If this works, it means your SSH key, DNS, firewall, and user account are all configured correctly.

```bash
# Using SSH config shorthand
ssh deb

# Or full form
ssh patDevOpsUser@${SERVER_IP}
```

**What to expect:**
- You should connect WITHOUT being asked for a password
- You'll see a welcome message or server prompt
- Your prompt should show: `patDevOpsUser@server011526-debian-ecom:~$`

**If it doesn't work:**
- Check that you updated the IP in `~/.ssh/config`
- Verify the key is in your SSH agent: `ssh-add -l`
- Try verbose mode to see what's wrong: `ssh -v deb`

### 6.2 Verify Docker Installation

**What this does:** Confirms that Docker was installed by cloud-init and that your user has permission to use it.

```bash
# Check Docker version
docker --version

# Check Docker is running
docker ps
```

**What to expect:**
- `docker --version` shows something like: `Docker version 24.0.x`
- `docker ps` shows an empty table (no containers running yet)
- No "permission denied" errors

**If you see permission errors:**
```bash
# You might need to log out and back in for group changes to take effect
exit
ssh deb
```

### 6.3 Verify CICD User

**What this does:** Tests that the GitHub Actions bot user exists and has the correct permissions (can use Docker with sudo).

```bash
# Switch to CICD user
sudo su - ghaCICDBotUser

# Test sudo privileges for Docker
sudo docker ps

# Exit back to your user
exit
```

**What to expect:**
- You can switch to `ghaCICDBotUser` without password
- `sudo docker ps` works (but may ask for password since this is first sudo use)
- Shows empty container list

**Why test this?** Later, GitHub Actions will SSH in as this user to deploy Docker containers. This confirms it will work.

---

## Phase 7: Deploy Nginx Proxy Manager

**What this does:** Deploys Nginx Proxy Manager (NPM) - your reverse proxy that will route web traffic to different containers and manage SSL certificates. This is the "front door" for all web traffic to your server.

**Why NPM?** It provides:
- Easy SSL certificate management (Let's Encrypt)
- Web UI for configuring proxy routes
- Automatic HTTPS redirects
- Access control and security headers

### 7.1 Transfer NPM Configuration

**What this does:** Copies your NPM docker-compose configuration from your laptop to the server using rsync.

From your laptop (not SSH'd into the server):

```bash
# Using SSH config shorthand
rsync -avvz ./nginxProxyMgr/ deb:~/nginxProxyMgr

# Or full form
rsync -avvz ./nginxProxyMgr/ patDevOpsUser@${SERVER_IP}:~/nginxProxyMgr
```

**What's being transferred:**
- `docker-compose.yml` - Defines NPM and PostgreSQL containers
- Any other configuration files in that directory

**What to expect:**
- You'll see file transfer progress
- Ends with: `total size is X  speedup is Y`

### 7.2 SSH into Server

**What this does:** Connects you to the server so you can run the Docker commands.

```bash
ssh deb
```

You're now on the server (not your laptop).

### 7.3 Start Nginx Proxy Manager

**What this does:** Launches the NPM and PostgreSQL containers. NPM will be accessible on port 81 for admin, and will handle ports 80 (HTTP) and 443 (HTTPS) for web traffic.

```bash
cd nginxProxyMgr

# Start in foreground to watch logs (good for first time)
docker compose up

# OR start in background and follow logs (preferred after testing)
docker compose up -d && docker compose logs -f nginx-proxy-mgr-020325
```

**What to expect:**
- Container images download (first time only, ~2-3 minutes)
- PostgreSQL starts first
- NPM connects to PostgreSQL
- Logs show: `Listening on port 81` or similar
- No error messages

**To exit logs:** Press `Ctrl+C` (if you used `-d`, containers keep running)

### 7.4 Access NPM Admin Panel

**What this does:** Opens the NPM web interface where you'll configure domains and SSL certificates.

Open browser to: `http://<your-server-ip>:81`

**⚠️ Important:** Use `http://` NOT `https://` - SSL isn't configured yet.

**Default credentials:**
- Email: `admin@example.com`
- Password: `changeme`

**IMMEDIATELY after first login:**
1. You'll be prompted to change email and password
2. Change them to something secure
3. Save your new credentials in 1Password

**If you can't access the admin panel:**
```bash
# Check if containers are running
docker ps

# Check logs for errors
docker compose logs nginx-proxy-mgr-020325

# Ensure port 81 isn't blocked
sudo ufw status
```

---

## Phase 8: Next Steps

**What you've accomplished:**
- ✅ Created SSH keys for human and CICD access
- ✅ Stored all secrets securely in 1Password
- ✅ Deployed a Debian server on DigitalOcean with Terraform
- ✅ Configured two user accounts with appropriate permissions
- ✅ Installed Docker
- ✅ Deployed Nginx Proxy Manager

**What's next:**

Now that your server is running and NPM is configured, you're ready to deploy your applications:

- [ ] **Configure domain DNS** - Point your domain to the server IP
- [ ] **Set up SSL certificates** - Use NPM to request Let's Encrypt certificates
- [ ] **Deploy Vendure** - eCommerce container for guitar marketplace
- [ ] **Deploy Astro** - Static site for marketing and luthier profiles  
- [ ] **Configure proxy hosts** - Route traffic from domains to containers
- [ ] **Implement security hardening** - Firewall, fail2ban, rate limiting (see security guide)

**Recommended next actions in order:**

1. **Get a domain name** if you don't have one (Namecheap, Cloudflare, etc.)
2. **Point DNS to your server IP** (create A records)
3. **In NPM, create proxy hosts** for your domains with SSL
4. **Deploy your application containers** (Vendure, Astro)
5. **Configure NPM proxy hosts** to route traffic to those containers
6. **Implement security** (this is critical - see security hardening guide)

---

## Troubleshooting

**When to use this section:** If something didn't work as expected during setup, check here for common solutions.

### SSH Connection Issues

**Problem:** Can't connect via SSH

**What this usually means:** The server isn't reachable, wrong IP, wrong key, or firewall blocking.

**Solutions:**
```bash
# 1. Check if server is reachable at all
ping ${SERVER_IP}

# 2. Use verbose SSH to see where it's failing
ssh -v deb

# 3. Check if correct key is being offered
ssh-add -l

# 4. Test SSH key fingerprint matches what's on GitHub/DO
ssh-keygen -l -f ~/.ssh/${SSH_KEY_NAME_HUMAN}

# 5. Try connecting with explicit key
ssh -i ~/.ssh/${SSH_KEY_NAME_HUMAN} patDevOpsUser@${SERVER_IP}
```

**Common causes:**
- Wrong IP in `~/.ssh/config` - double-check it matches server
- SSH key not in agent - run `ssh-add ~/.ssh/keyname`
- Firewall blocking port 22 - check DigitalOcean firewall settings
- Server still booting - wait 2-3 minutes after `terraform apply`

### Environment Variables Not Set

**Problem:** Terraform says variables are missing

**What this means:** The environment variables you exported in Phase 4 aren't in your current shell session.

**Solution:**
```bash
# Re-export all variables (run Phase 4 commands again)
ITEM_1P="server011526-debian-ecom"
export DIGITALOCEAN_ACCESS_TOKEN=$(op item get ${ITEM_1P} --fields label=DOToken_FA_011526)
# ... etc (all the export commands from Phase 4)
```

**Why this happens:**
- You closed the terminal and opened a new one
- You ran Terraform in a different terminal window
- You ran `unset` on the variables accidentally

**Tip:** Keep the terminal window open while working through phases 4-5.

### Docker Not Found

**Problem:** `docker: command not found` on server

**What this means:** Either Docker didn't install during cloud-init, or you need to log out/in for group permissions.

**Solutions:**
```bash
# 1. Check if Docker is installed
which docker

# 2. If not installed, install manually
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 3. Add your user to docker group
sudo usermod -aG docker $USER

# 4. Log out and back in for group changes to take effect
exit
ssh deb

# 5. Verify Docker works now
docker ps
```

**Why this happens:**
- Cloud-init script failed or is still running (check with `sudo cloud-init status`)
- User not in docker group yet (group membership requires re-login)

### Can't Access NPM Dashboard

**Problem:** Can't reach `http://<ip>:81`

**What this means:** Container isn't running, port is blocked, or using wrong protocol.

**Solutions:**
```bash
# 1. Check if containers are running
docker ps

# 2. Check container logs for errors
docker compose logs nginx-proxy-mgr-020325

# 3. Ensure port 81 isn't blocked by firewall
sudo ufw status

# 4. Verify you're using HTTP not HTTPS
# Wrong:  https://123.45.67.89:81
# Right:  http://123.45.67.89:81
```

**Common causes:**
- Using `https://` instead of `http://` (SSL not configured yet on port 81)
- Container didn't start - check logs
- Firewall blocking port 81 - run `sudo ufw allow 81/tcp`
- Wrong IP address - double-check server IP

### 1Password CLI Errors

**Problem:** `op` commands fail or return empty values

**What this means:** Not authenticated to 1Password or wrong item/field names.

**Solutions:**
```bash
# 1. Check if authenticated
op whoami

# 2. If not, sign in
op signin

# 3. Verify item exists
op item list --vault "Z_Tech_ClicksAndCodes"

# 4. Check field names match exactly
op item get "server011526-debian-ecom" --format json

# 5. Test retrieving a specific field
op item get "server011526-debian-ecom" --fields label=DOToken_FA_011526
```

**Common causes:**
- Not signed into 1Password - run `op signin`
- Wrong vault name - check exact spelling (case-sensitive)
- Wrong item name - check exact spelling (case-sensitive)
- Wrong field label - must match exactly what's in 1Password

### Terraform Errors

**Problem:** `terraform apply` fails

**What this means:** Depends on the error message, but usually: wrong credentials, quota limits, or syntax errors.

**Solutions:**
```bash
# 1. Check DigitalOcean token is valid
echo $DIGITALOCEAN_ACCESS_TOKEN

# 2. Validate Terraform syntax
terraform validate

# 3. Re-initialize if provider errors
rm -rf .terraform .terraform.lock.hcl
terraform init

# 4. Check DigitalOcean account limits
doctl account get

# 5. Read the actual error message carefully
# Terraform error messages are usually specific about what's wrong
```

**Common causes:**
- Invalid or expired DigitalOcean token
- Terraform variables not exported (see "Environment Variables Not Set" above)
- DigitalOcean account limit reached (droplet quota)
- SSH key already exists with same name in DigitalOcean
- Syntax error in `.tf` file

---

## Clean Up / Destroy

**When to use this:** If you need to tear down the server (testing, starting over, or shutting down the project).

**⚠️ Warning:** This is destructive and irreversible. All data on the server will be lost.

If you need to tear down the server:

```bash
# Destroy all Terraform-managed infrastructure
terraform destroy

# Type 'yes' to confirm
```

**What happens:**
- Droplet is deleted from DigitalOcean
- IP address is released
- You stop being charged for the droplet

**What's NOT deleted:**
- SSH keys in DigitalOcean (they're reusable)
- SSH keys on GitHub (they're reusable)
- 1Password data (kept for reference)
- Your local SSH keys (still on your laptop)
- Managed PostgreSQL database (if you created one - must delete separately)

**Optionally remove SSH keys from DO/GH:**
```bash
# List and delete from DigitalOcean
doctl compute ssh-key list
doctl compute ssh-key delete <key-id>

# List and delete from GitHub  
gh ssh-key list
gh ssh-key delete <key-id>
```

**When to keep SSH keys:**
- You plan to create another server later
- You use these keys for other servers

**When to delete SSH keys:**
- This was a one-time test
- You're creating fresh keys for a new project
- Security: you suspect a key was compromised

---

## Notes

**Philosophy:** All commands in this guide are designed for **individual copy-paste execution** rather than running one giant script. This approach:
- Helps you understand what each step does
- Makes debugging easier when something fails  
- Gives you control to skip or modify steps
- Teaches the underlying tools (1Password CLI, GitHub CLI, doctl, Terraform)

**Best practices:**
- Keep your 1Password item updated as the single source of truth
- Server IP is automatically stored back to 1Password by Terraform
- CICD bot's private key will be added to GitHub repo secrets later (per-repo basis)
- Take your time through each phase - rushing leads to mistakes
- If you get confused, re-read the "What this does" sections

**Security reminder:**
This setup guide focuses on getting infrastructure running. Phase 8 mentions security hardening - **don't skip this**. At minimum:
- Set up DigitalOcean Cloud Firewall
- Configure UFW on the server
- Install and configure fail2ban
- Consider adding Cloudflare in front

See the separate security hardening guide for detailed instructions.

**Getting help:**
- Terraform docs: https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs
- DigitalOcean docs: https://docs.digitalocean.com/
- Nginx Proxy Manager: https://nginxproxymanager.com/
- Docker Compose: https://docs.docker.com/compose/

**What's next:**
Once you've completed this guide, you have a solid foundation for deploying your guitar marketplace. The next major steps are:
1. Deploy Vendure (eCommerce)
2. Deploy Astro (static site)
3. Configure NPM proxy hosts
4. Security hardening
5. Application-specific configuration
