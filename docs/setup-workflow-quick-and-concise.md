# Quick Setup Commands - server011526-debian-ecom


## Prerequisites

- 1Password account with desktop app installed
- 1Password CLI tool installed and authenticated (`op signin`)
  - [Get started with 1Password CLI](https://developer.1password.com/docs/cli/get-started/)
- GitHub CLI installed (`gh --version`)
  - [GitHub CLI quickstart](https://docs.github.com/en/github-cli/github-cli/quickstart)
- DigitalOcean CLI installed (`doctl version`)
  - [How to Install and Configure doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/)
- Terraform installed (`terraform version`)


# Ok, now you're ready to run these commands, which mostly automate the project setup.

Run the following commands, in order, as code blocks.

## Configuration Variables

**EDIT THESE FIRST** - Customize these values for your project, then copy/paste this entire block to set your configuration. All subsequent commands will use these variables.

### Be careful when you paste these-- Don't immediately press enter.  Double check the input's first characters and last characters.  Sometimes CLI apps add extra characters at the beginning or end of a code block.

##

```bash
# Env vars.  Following pattern: export <variableName>=<value>
# Basically, here, we're just preparing for later steps where we reference these by their variable names.  So, don't edit the variable names, but be sure to double check the values and edit them if necessary-- such as the date, your email, desired ssh key names, etc.
# Your Information
export EMAIL=patrick.wm.meaney@gmail.com

# Project Naming (update the date/identifier to match your project)
export PROJECT_DATE=011526
export SSH_KEY_NAME_HUMAN=id_ed25519_${PROJECT_DATE}_humanuser
export SSH_KEY_NAME_CICD=id_ed25519_${PROJECT_DATE}_cicd

# 1Password Configuration
export VAULT_1P=Z_Tech_ClicksAndCodes
export ITEM_1P="server011526-debian-ecom"

# 1Password Field Names (created below in Step 1 - "Create Tokens in Browser")
export FIELD_1P_DO_TOKEN=DOToken_FA_011526
export FIELD_1P_GH_TOKEN=GHPATCICD_RpoWkflo_WRDpckgs_011526

# Linux User Configuration
export LINUX_HUMAN_USERNAME=patDevOpsUser
export LINUX_BOTCICDGHA_USERNAME=ghaCICDBotUser
export LINUX_SERVER_NAME=server011526-debian-ecom
```

---

## Step 1: 1Password Item Setup & Manual Token Creation


### Create 1Password Item

```bash
# Create the 1Password Secure Note item with initial fields
op item create --category "Secure Note" \
  --title "$ITEM_1P" \
  --vault "$VAULT_1P" \
  "${FIELD_1P_DO_TOKEN}[password]=DO_TOKEN_PLACEHOLDER" \
  "${FIELD_1P_GH_TOKEN}[password]=GH_TOKEN_PLACEHOLDER" \
  "LINUX_HUMAN_USERNAME[text]=${LINUX_HUMAN_USERNAME}" \
  "LINUX_BOTCICDGHA_USERNAME[text]=${LINUX_BOTCICDGHA_USERNAME}" \
  "LINUX_SERVER_NAME[text]=${LINUX_SERVER_NAME}" \
  "VAULT_1P[text]=${VAULT_1P}" \
  "LINUX_SERVER_IPADDRESS[text]="
```


### Create Tokens in Browser

**DigitalOcean Token:**
1. DigitalOcean Dashboard → API → Generate New Token
2. Name: Use the value of `$FIELD_1P_DO_TOKEN` from configuration section above (e.g., `DOToken_FA_011526`)
3. Scopes: Full Access
4. Copy token immediately and replace the FIELD_1P_DO_TOKEN's "DO_TOKEN_PLACEHOLDER" value with the token value

**GitHub Token:**
1. GitHub → Settings → Developer Settings → Personal Access Tokens → Generate new token (classic)
2. Name: Use the value of `$FIELD_1P_GH_TOKEN` from configuration section above (e.g., `GHPATCICD_RpoWkflo_WRDpckgs_011526`)
3. Scopes: repo, workflow, write:packages, read:packages, delete:packages, read:org, admin:public_key
4. Copy token immediately  and replace the FIELD_1P_GH_TOKEN's "GH_TOKEN_PLACEHOLDER" value with the token value

---

## Step 2: Generate Human SSH Key

```bash
# Generate human SSH key
ssh-keygen -t ed25519 -C "${EMAIL}" -f ~/.ssh/${SSH_KEY_NAME_HUMAN} -N ""

# Add to SSH agent
ssh-add ~/.ssh/${SSH_KEY_NAME_HUMAN}

# Add to SSH config.  Note: replace 'deb' with your preferred ssh host name.  In this example we'd run `ssh deb` to log into server from CLI.
cat << EOF >> ~/.ssh/config

# ${ITEM_1P} - Human User
Host deb
    User ${LINUX_HUMAN_USERNAME}
    Hostname PLACEHOLDER_IP
    IdentityFile ~/.ssh/${SSH_KEY_NAME_HUMAN}

EOF

# Upload public key to 1Password
op item edit "$ITEM_1P" --vault "$VAULT_1P" "${SSH_KEY_NAME_HUMAN}[text]=$(cat ~/.ssh/${SSH_KEY_NAME_HUMAN}.pub)"

# Upload to GitHub (note: Because its stored as 1password "password" field, it won't work without `--reveal`.  If successful, shows no output, so the token isnt revealed in the CLI either.  typically no biggie, since it's just a developer at work. But could be relevant if you're doing a screenshare or recording)
echo "$(op item get "${ITEM_1P}" --vault "${VAULT_1P}" --field "${FIELD_1P_GH_TOKEN}" --reveal)" | gh auth login --with-token
gh ssh-key add ~/.ssh/${SSH_KEY_NAME_HUMAN}.pub -t "${SSH_KEY_NAME_HUMAN}"

# Upload to DigitalOcean (note: Because its stored as 1password "password" field, it won't work without `--reveal`.)
doctl auth init --context default --access-token "$(op item get "${ITEM_1P}" --vault "${VAULT_1P}" --field "${FIELD_1P_DO_TOKEN}" --reveal)"
doctl compute ssh-key create "${SSH_KEY_NAME_HUMAN}" --public-key "$(cat ~/.ssh/${SSH_KEY_NAME_HUMAN}.pub)"
```

---

## Step 3: Generate CICD SSH Key

```bash
# Generate CICD SSH key
ssh-keygen -t ed25519 -C "${EMAIL}" -f ~/.ssh/${SSH_KEY_NAME_CICD} -N ""

# Add to SSH agent
ssh-add ~/.ssh/${SSH_KEY_NAME_CICD}

# Upload public key to 1Password
op item edit "$ITEM_1P" --vault "$VAULT_1P" "${SSH_KEY_NAME_CICD}[text]=$(cat ~/.ssh/${SSH_KEY_NAME_CICD}.pub)"

# Upload to GitHub
gh ssh-key add ~/.ssh/${SSH_KEY_NAME_CICD}.pub -t "${SSH_KEY_NAME_CICD}"

# Upload to DigitalOcean
doctl compute ssh-key create "${SSH_KEY_NAME_CICD}" --public-key "$(cat ~/.ssh/${SSH_KEY_NAME_CICD}.pub)"
```

---

## Step 4: Verify Keys

```bash
# Verify keys in SSH agent
ssh-add -l

# Verify keys on GitHub
# You can ignore any warning about "This API operation needs the "admin:ssh_signing_key" scope." -- That's irrelevant for this project
gh ssh-key list

# Verify keys on DigitalOcean
doctl compute ssh-key list

# Verify keys in 1Password
op item get "${ITEM_1P}" --vault "${VAULT_1P}" --fields label=${SSH_KEY_NAME_HUMAN}
op item get "${ITEM_1P}" --vault "${VAULT_1P}" --fields label=${SSH_KEY_NAME_CICD}
```

---

## Step 5: Export Environment Variables for Terraform

Here, we're just setting items into the OS env, for subsequent use with Terraform.  Most of them use "TF_VAR_" as a prefix-- which is require for terraform to pick these up and use them in its code files.

**Note:** These must be pasted into the same terminal session where the posted the previous command-- otherwise the terminal won't find them.

**Note:** This first thing (ITEM_1P) should already be set, from the earliest step in this file ("Configuration Variables").  But just in case, feel free to re-run it here.  Just ensure it matches the earlier version
```bash

# Set the item name first
ITEM_1P="server011526-debian-ecom"

# Export DigitalOcean token
export DIGITALOCEAN_ACCESS_TOKEN=$(op item get ${ITEM_1P} --fields label=${FIELD_1P_DO_TOKEN} --reveal)

# Export Terraform variables
export TF_VAR_LINUX_SERVER_NAME=$(op item get ${ITEM_1P} --fields label=LINUX_SERVER_NAME)
export TF_VAR_LINUX_HUMAN_USERNAME=$(op item get ${ITEM_1P} --fields label=LINUX_HUMAN_USERNAME)
export TF_VAR_LINUX_HUMAN_SSHKEY=$(op item get ${ITEM_1P} --fields label=${SSH_KEY_NAME_HUMAN})
export TF_VAR_LINUX_BOTCICDGHA_USERNAME=$(op item get ${ITEM_1P} --fields label=LINUX_BOTCICDGHA_USERNAME)
export TF_VAR_LINUX_CICDGHA_SSHKEY=$(op item get ${ITEM_1P} --fields label=${SSH_KEY_NAME_CICD})
export TF_VAR_VAULT_1P=$(op item get ${ITEM_1P} --fields label=VAULT_1P)
export TF_VAR_ITEM_1P=${ITEM_1P}
```

---

## Step 6: Verify Environment Variables

```bash
# Verify all variables are set
echo $DIGITALOCEAN_ACCESS_TOKEN
echo $TF_VAR_LINUX_SERVER_NAME
echo $TF_VAR_LINUX_HUMAN_USERNAME
echo $TF_VAR_LINUX_BOTCICDGHA_USERNAME
```

---

## Step 7: Run Terraform

```bash
# Navigate to project directory
cd /path/to/server011526-debian-ecom

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Apply configuration
terraform apply
# Type 'yes' when prompted

# Get server IP
terraform output
```

---

## Step 8: Update SSH Config with Real IP

Originally, we setup the developer's desktop with a ~/.ssh/config file which includes a placeholder IP.
Now that the server is created, we'll need to update that with the server's actual IP, so we can ssh into it.

```bash
# Get IP from 1Password
export SERVER_IP=$(op item get ${ITEM_1P} --fields label=LINUX_SERVER_IPADDRESS)
echo $SERVER_IP

# Edit ~/.ssh/config and replace PLACEHOLDER_IP with actual IP
# Or use sed:
sed -i '' 's/PLACEHOLDER_IP/YOUR_ACTUAL_IP/' ~/.ssh/config
```

---

## Step 9: Test SSH Connection

```bash
# SSH into server
ssh deb

# Verify Docker is installed
docker --version
docker ps

# Exit
exit
```

---

## Step 10: Deploy Nginx Proxy Manager

```bash
# From your laptop, transfer NPM config
rsync -avvz ./nginxProxyMgr/ deb:~/nginxProxyMgr

# SSH into server
ssh deb

# Start NPM
cd nginxProxyMgr
docker compose up -d && docker compose logs -f nginx-proxy-mgr-020325

# Access NPM at http://YOUR_SERVER_IP:81
# Default login: admin@example.com / changeme
```