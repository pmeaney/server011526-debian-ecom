# Shell Command Reference - server011526-debian-ecom

Quick reference for all shell commands used in this project, organized by category.

---

## SSH Key Operations

### Generate SSH Key (No Password)
```bash
ssh-keygen -t ed25519 -C "your.email@example.com" -f ~/.ssh/keyname -N ""
```
Creates an Ed25519 SSH key pair with no password protection.

### Generate SSH Key (With Password)
```bash
ssh-keygen -t ed25519 -C "your.email@example.com" -f ~/.ssh/keyname
```
Creates an Ed25519 SSH key pair and prompts for password.

### Add SSH Key to Agent
```bash
ssh-add ~/.ssh/keyname
```
Adds private key to SSH agent for automatic authentication.

### List SSH Keys in Agent
```bash
ssh-add -l
```
Shows all SSH keys currently loaded in the agent.

### Remove SSH Key from Agent
```bash
ssh-add -d ~/.ssh/keyname
```
Removes a specific key from the SSH agent.

### View SSH Key Fingerprint
```bash
ssh-keygen -l -f ~/.ssh/keyname
```
Displays the fingerprint of an SSH key (useful for verification).

### View Public Key Contents
```bash
cat ~/.ssh/keyname.pub
```
Displays the public key content for copying.

### Test SSH Connection
```bash
ssh -T git@github.com
```
Tests SSH connection to GitHub.

### Verbose SSH for Debugging
```bash
ssh -v user@hostname
```
Shows detailed connection information for troubleshooting.

### SSH Config File Editing
```bash
nano ~/.ssh/config
```
Edit SSH configuration for connection shortcuts.

---

## 1Password CLI Operations

### Sign In to 1Password
```bash
op signin
```
Authenticate to 1Password account.

### Create New Item
```bash
op item create --category "Secure Note" --title "ItemName" --vault "VaultName"
```
Creates a new Secure Note item.

### Create Item with Fields
```bash
op item create --category "Secure Note" \
  --title "ItemName" \
  --vault "VaultName" \
  "field1[text]=value1" \
  "field2[password]=value2"
```
Creates item with initial fields (quote each field for zsh compatibility).

### Get Item Field Value
```bash
op item get "ItemName" --vault "VaultName" --fields label=FieldLabel
```
Retrieves a specific field value from a 1Password item.

### Get Item Field Value (Password Field)
```bash
op item get "ItemName" --vault "VaultName" --fields label=FieldLabel --reveal
```
Retrieves a password field value - requires --reveal flag to get actual value instead of placeholder.

### Get Item Field (Alternative Syntax)
```bash
op item get "ItemName" --fields label=FieldLabel
```
Retrieves field when default vault is set.

### Edit Item - Add/Update Field
```bash
op item edit "ItemName" --vault "VaultName" "FieldLabel[text]=value"
```
Adds or updates a text field in a 1Password item.

### Edit Item - Add Public SSH Key
```bash
op item edit "ItemName" --vault "VaultName" "keyname[text]=$(cat ~/.ssh/keyname.pub)"
```
Stores SSH public key content in 1Password.

### List All Items in Vault
```bash
op item list --vault "VaultName"
```
Shows all items in a specific vault.

### Get Entire Item as JSON
```bash
op item get "ItemName" --format json
```
Retrieves complete item data in JSON format.

---

## GitHub CLI Operations

### Check GitHub CLI Version
```bash
gh --version
```
Verifies GitHub CLI is installed and shows version.

### Login with Token
```bash
echo "token_here" | gh auth login --with-token
```
Authenticates GitHub CLI using a personal access token.

### Login with Token from 1Password
```bash
echo "$(op item get "ItemName" --vault "VaultName" --field "TokenField" --reveal)" | gh auth login --with-token
```
Authenticates using token stored in 1Password (requires --reveal for password fields).

### Check Auth Status
```bash
gh auth status
```
Shows current authentication status and logged-in user.

### Add SSH Key to GitHub
```bash
gh ssh-key add ~/.ssh/keyname.pub -t "key-description"
```
Uploads SSH public key to GitHub account.

### List GitHub SSH Keys
```bash
gh ssh-key list
```
Shows all SSH keys associated with your GitHub account.

### Delete GitHub SSH Key
```bash
gh ssh-key delete <key-id>
```
Removes an SSH key from GitHub account.

### Test GitHub SSH Connection
```bash
ssh -T git@github.com
```
Verifies SSH key authentication with GitHub.

---

## DigitalOcean CLI Operations

### Check doctl Version
```bash
doctl version
```
Verifies DigitalOcean CLI is installed and shows version.

### Authenticate with Token
```bash
doctl auth init --context default --access-token "token_here"
```
Authenticates doctl with DigitalOcean API.

### Authenticate with Token from 1Password
```bash
doctl auth init --context default --access-token "$(op item get "ItemName" --vault "VaultName" --field "TokenField" --reveal)"
```
Authenticates using token stored in 1Password (requires --reveal for password fields).

### List Auth Contexts
```bash
doctl auth list
```
Shows all configured authentication contexts.

### Switch Auth Context
```bash
doctl auth switch --context context-name
```
Changes active authentication context.

### Create SSH Key on DigitalOcean
```bash
doctl compute ssh-key create "key-name" --public-key "$(cat ~/.ssh/keyname.pub)"
```
Uploads SSH public key to DigitalOcean account.

### List DigitalOcean SSH Keys
```bash
doctl compute ssh-key list
```
Shows all SSH keys in your DigitalOcean account.

### Delete DigitalOcean SSH Key
```bash
doctl compute ssh-key delete <key-id>
```
Removes an SSH key from DigitalOcean account.

### List Droplets
```bash
doctl compute droplet list
```
Shows all droplets in your DigitalOcean account.

### Get Droplet Details
```bash
doctl compute droplet get <droplet-id>
```
Shows detailed information about a specific droplet.

### Delete Droplet
```bash
doctl compute droplet delete <droplet-id>
```
Destroys a specific droplet.

---

## Terraform Operations

### Initialize Terraform
```bash
terraform init
```
Downloads providers and prepares Terraform working directory.

### Validate Configuration
```bash
terraform validate
```
Checks Terraform configuration for syntax errors.

### Format Configuration Files
```bash
terraform fmt
```
Automatically formats .tf files to canonical style.

### Show Execution Plan
```bash
terraform plan
```
Previews changes Terraform will make without applying them.

### Apply Configuration
```bash
terraform apply
```
Creates/updates infrastructure according to configuration.

### Apply with Auto-Approve
```bash
terraform apply -auto-approve
```
Applies changes without confirmation prompt (use carefully).

### Show Current State
```bash
terraform show
```
Displays current Terraform state.

### List Resources
```bash
terraform state list
```
Shows all resources managed by Terraform.

### Show Outputs
```bash
terraform output
```
Displays all output values from configuration.

### Show Specific Output
```bash
terraform output output-name
```
Displays a specific output value.

### Destroy Infrastructure
```bash
terraform destroy
```
Removes all resources managed by Terraform.

### Refresh State
```bash
terraform refresh
```
Updates Terraform state to match real infrastructure.

### Import Existing Resource
```bash
terraform import resource-type.name resource-id
```
Brings existing infrastructure under Terraform management.

---

## Environment Variable Operations

### Export Single Variable
```bash
export VAR_NAME=value
```
Sets an environment variable for current shell session.

### Export from 1Password
```bash
export VAR_NAME=$(op item get "ItemName" --fields label=FieldLabel)
```
Exports variable with value retrieved from 1Password.

### Export from 1Password (Password Field)
```bash
export VAR_NAME=$(op item get "ItemName" --fields label=FieldLabel --reveal)
```
Exports password field value - requires --reveal flag.

### View Environment Variable
```bash
echo $VAR_NAME
```
Displays the value of an environment variable.

### List All Environment Variables
```bash
env
```
Shows all current environment variables.

### Unset Environment Variable
```bash
unset VAR_NAME
```
Removes an environment variable from current session.

### Export Multiple Variables (Block)
```bash
export VAR1=value1
export VAR2=value2
export VAR3=value3
```
Sets multiple environment variables at once.

---

## Docker Operations

### Check Docker Version
```bash
docker --version
```
Verifies Docker is installed and shows version.

### List Running Containers
```bash
docker ps
```
Shows all currently running containers.

### List All Containers (Including Stopped)
```bash
docker ps -a
```
Shows all containers regardless of state.

### View Container Logs
```bash
docker logs container-name
```
Displays logs from a specific container.

### Follow Container Logs (Real-time)
```bash
docker logs -f container-name
```
Streams container logs in real-time.

### Execute Command in Container
```bash
docker exec -it container-name /bin/bash
```
Opens interactive shell inside running container.

### Stop Container
```bash
docker stop container-name
```
Gracefully stops a running container.

### Start Container
```bash
docker start container-name
```
Starts a stopped container.

### Restart Container
```bash
docker restart container-name
```
Restarts a running container.

### Remove Container
```bash
docker rm container-name
```
Deletes a stopped container.

### Remove Running Container (Force)
```bash
docker rm -f container-name
```
Forcefully stops and removes a container.

### List Docker Images
```bash
docker images
```
Shows all Docker images on the system.

### Remove Docker Image
```bash
docker rmi image-name:tag
```
Deletes a Docker image.

### Pull Docker Image
```bash
docker pull image-name:tag
```
Downloads a Docker image from registry.

### View Docker Networks
```bash
docker network ls
```
Lists all Docker networks.

### Inspect Docker Network
```bash
docker network inspect network-name
```
Shows detailed information about a network.

### View Containers on Network
```bash
docker network inspect network-name -f '{{range .Containers}}{{.Name}} {{end}}'
```
Lists all containers connected to a network.

### Prune Unused Resources
```bash
docker system prune
```
Removes unused containers, networks, and images.

### View Docker Disk Usage
```bash
docker system df
```
Shows disk space used by Docker resources.

---

## Docker Compose Operations

### Start Services (Foreground)
```bash
docker compose up
```
Starts all services and shows logs in terminal.

### Start Services (Background)
```bash
docker compose up -d
```
Starts all services in detached mode.

### Start with Build
```bash
docker compose up --build
```
Rebuilds images before starting services.

### Start with Remove Orphans
```bash
docker compose up --remove-orphans
```
Removes containers for services not in compose file.

### Full Startup Command
```bash
docker compose up --build --remove-orphans -d
```
Builds, starts detached, and removes orphans.

### View Logs
```bash
docker compose logs
```
Shows logs from all services.

### Follow Logs
```bash
docker compose logs -f
```
Streams logs in real-time from all services.

### Follow Specific Service Logs
```bash
docker compose logs -f service-name
```
Streams logs from a specific service.

### Stop Services
```bash
docker compose down
```
Stops and removes all containers defined in compose file.

### Stop and Remove Volumes
```bash
docker compose down -v
```
Stops containers and removes associated volumes.

### List Services
```bash
docker compose ps
```
Shows status of all services in compose file.

### Restart Services
```bash
docker compose restart
```
Restarts all services.

### Restart Specific Service
```bash
docker compose restart service-name
```
Restarts a single service.

### Execute Command in Service
```bash
docker compose exec service-name command
```
Runs a command in a running service container.

### View Service Configuration
```bash
docker compose config
```
Validates and displays merged compose configuration.

---

## File Transfer Operations (rsync)

### Basic rsync Syntax
```bash
rsync -avvz /local/path/ user@host:/remote/path/
```
Syncs local directory to remote server with verbose output.

### rsync with SSH Config Shorthand
```bash
rsync -avvz ./local/ hostname:~/remote/
```
Uses SSH config alias instead of full user@host.

### rsync Dry Run
```bash
rsync -avvzn /local/path/ user@host:/remote/path/
```
Shows what would be transferred without actually copying.

### rsync with Delete
```bash
rsync -avvz --delete /local/path/ user@host:/remote/path/
```
Syncs and removes files on destination that don't exist in source.

### rsync with Progress
```bash
rsync -avvz --progress /local/path/ user@host:/remote/path/
```
Shows progress during file transfer.

### Install rsync on Remote Server
```bash
sudo apt install rsync -y
```
Installs rsync package on Debian/Ubuntu.

---

## Server Management Operations

### SSH into Server (Config Shorthand)
```bash
ssh hostname
```
Connects using SSH config alias.

### SSH into Server (Full Form)
```bash
ssh user@ip-address
```
Connects with explicit username and IP.

### SSH with Specific Key
```bash
ssh -i ~/.ssh/keyname user@hostname
```
Connects using a specific private key.

### Check Server Uptime
```bash
uptime
```
Shows how long server has been running and load averages.

### Check Disk Usage
```bash
df -h
```
Displays disk space usage in human-readable format.

### Check Memory Usage
```bash
free -h
```
Shows memory (RAM) usage.

### Check Running Processes
```bash
htop
```
Interactive process viewer (better than `top`).

### Check Network Interfaces
```bash
ip addr show
```
Displays all network interfaces and IP addresses.

### Get Docker Bridge IP
```bash
ip addr show docker0
```
Shows Docker's default bridge network IP (usually 172.17.0.1).

### Test Network Connectivity
```bash
ping hostname-or-ip
```
Tests if a host is reachable.

### Check Open Ports
```bash
sudo netstat -tulpn
```
Shows all listening ports and associated programs.

### Check Firewall Status
```bash
sudo ufw status
```
Shows UFW firewall status and rules.

### View System Logs
```bash
sudo journalctl -f
```
Follows system logs in real-time.

### Reboot Server
```bash
sudo reboot
```
Restarts the server.

### Shutdown Server
```bash
sudo shutdown -h now
```
Shuts down the server immediately.

---

## Package Management (Debian/Ubuntu)

### Update Package Lists
```bash
sudo apt-get update
```
Refreshes available package information from repositories.

### Upgrade Installed Packages
```bash
sudo apt-get upgrade
```
Upgrades all installed packages to latest versions.

### Install Package
```bash
sudo apt-get install package-name
```
Installs a specific package.

### Install with Auto-Yes
```bash
sudo apt-get install package-name -y
```
Installs without confirmation prompt.

### Remove Package
```bash
sudo apt-get remove package-name
```
Removes a package but keeps configuration files.

### Completely Remove Package
```bash
sudo apt-get purge package-name
```
Removes package and all configuration files.

### Clean Package Cache
```bash
sudo apt-get clean
```
Removes downloaded package files from cache.

### Auto-Remove Unused Packages
```bash
sudo apt-get autoremove
```
Removes packages that were installed as dependencies but are no longer needed.

---

## Git Operations

### Clone Repository
```bash
git clone repository-url
```
Downloads a repository to local machine.

### Check Repository Status
```bash
git status
```
Shows current branch and file changes.

### Add Files to Staging
```bash
git add filename
```
Stages a specific file for commit.

### Add All Changes
```bash
git add .
```
Stages all modified and new files.

### Commit Changes
```bash
git commit -m "commit message"
```
Commits staged changes with a message.

### Push to Remote
```bash
git push origin branch-name
```
Uploads commits to remote repository.

### Pull from Remote
```bash
git pull origin branch-name
```
Downloads and merges changes from remote.

### View Commit History
```bash
git log
```
Shows commit history.

### View Remote URLs
```bash
git remote -v
```
Displays configured remote repositories.

---

## Nginx Proxy Manager Specific

### Access NPM Admin Panel
```
http://server-ip:81
```
Web interface for Nginx Proxy Manager configuration.

### NPM Default Credentials
```
Email: admin@example.com
Password: changeme
```
Initial login credentials (change immediately).

### View NPM Container Logs
```bash
docker compose logs -f nginx-proxy-mgr-020325
```
Streams Nginx Proxy Manager logs.

### Restart NPM
```bash
docker compose restart nginx-proxy-mgr-020325
```
Restarts Nginx Proxy Manager service.

---

## Security & Hardening

### Check fail2ban Status
```bash
sudo systemctl status fail2ban
```
Shows if fail2ban service is running.

### View fail2ban Jails
```bash
sudo fail2ban-client status
```
Lists all active fail2ban jails.

### Check Specific fail2ban Jail
```bash
sudo fail2ban-client status jail-name
```
Shows detailed status of a specific jail.

### Enable UFW Firewall
```bash
sudo ufw enable
```
Activates UFW firewall.

### Allow Port Through UFW
```bash
sudo ufw allow 22/tcp
```
Opens a specific port in UFW firewall.

### Deny Port Through UFW
```bash
sudo ufw deny 22/tcp
```
Blocks a specific port in UFW firewall.

### Check SSH Configuration
```bash
sudo nano /etc/ssh/sshd_config
```
Edit SSH server configuration.

### Restart SSH Service
```bash
sudo systemctl restart sshd
```
Applies SSH configuration changes.

---

## Troubleshooting Commands

### Test Port Connectivity
```bash
telnet hostname port
```
Tests if a port is open and accepting connections.

### Trace Network Route
```bash
traceroute hostname
```
Shows network path to destination.

### DNS Lookup
```bash
nslookup domain.com
```
Queries DNS for domain information.

### Check SSL Certificate
```bash
openssl s_client -connect domain.com:443
```
Shows SSL certificate details for a domain.

### View Active SSH Connections
```bash
who
```
Shows currently logged-in users.

### Kill User Session
```bash
sudo pkill -u username
```
Terminates all processes for a user.

### Check Disk I/O
```bash
sudo iotop
```
Shows real-time disk I/O usage by process.

---

## Quick Reference Snippets

### Export All Environment Variables at Once
```bash
ITEM_1P="server011526-debian-ecom"
# Note: --reveal required for password fields (DO and GH tokens)
export DIGITALOCEAN_ACCESS_TOKEN=$(op item get ${ITEM_1P} --fields label=DOToken_FA_011526 --reveal)
export TF_VAR_LINUX_SERVER_NAME=$(op item get ${ITEM_1P} --fields label=LINUX_SERVER_NAME)
export TF_VAR_LINUX_HUMAN_USERNAME=$(op item get ${ITEM_1P} --fields label=LINUX_HUMAN_USERNAME)
export TF_VAR_LINUX_HUMAN_SSHKEY=$(op item get ${ITEM_1P} --fields label=id_ed25519_011526_humanuser)
export TF_VAR_LINUX_BOTCICDGHA_USERNAME=$(op item get ${ITEM_1P} --fields label=LINUX_BOTCICDGHA_USERNAME)
export TF_VAR_LINUX_CICDGHA_SSHKEY=$(op item get ${ITEM_1P} --fields label=id_ed25519_011526_cicd)
export TF_VAR_VAULT_1P=$(op item get ${ITEM_1P} --fields label=VAULT_1P)
export TF_VAR_ITEM_1P=${ITEM_1P}
```

### Full NPM Deployment Workflow
```bash
# Transfer config to server
rsync -avvz ./nginxProxyMgr/ deb:~/nginxProxyMgr

# SSH into server
ssh deb

# Start NPM
cd nginxProxyMgr
docker compose up -d && docker compose logs -f nginx-proxy-mgr-020325
```

### Complete SSH Key Setup (Human User)
```bash
export EMAIL=patrick.wm.meaney@gmail.com
export SSH_KEY_NAME_HUMAN=id_ed25519_011526_humanuser
export VAULT_1P=Z_Tech_ClicksAndCodes
export ITEM_1P="server011526-debian-ecom"

ssh-keygen -t ed25519 -C "${EMAIL}" -f ~/.ssh/${SSH_KEY_NAME_HUMAN} -N ""
ssh-add ~/.ssh/${SSH_KEY_NAME_HUMAN}
op item edit "$ITEM_1P" --vault "$VAULT_1P" "${SSH_KEY_NAME_HUMAN}[text]=$(cat ~/.ssh/${SSH_KEY_NAME_HUMAN}.pub)"
gh ssh-key add ~/.ssh/${SSH_KEY_NAME_HUMAN}.pub -t "${SSH_KEY_NAME_HUMAN}"
doctl compute ssh-key create "${SSH_KEY_NAME_HUMAN}" --public-key "$(cat ~/.ssh/${SSH_KEY_NAME_HUMAN}.pub)"
```

---

## Notes

- All commands are tested on Debian 12 / Ubuntu systems
- SSH commands assume key-based authentication is configured
- Docker commands assume user is in `docker` group
- 1Password CLI commands require active session (`op signin`)
- **1Password password fields require `--reveal` flag** to retrieve actual values
- Terraform commands must be run from project directory
- Environment variables only persist for current shell session
- When using zsh, wrap 1Password field assignments in quotes to prevent glob expansion