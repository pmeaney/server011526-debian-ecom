# Environment Variable Reload

Use this when reloading your environment for the server011526-debian-ecom project after closing your terminal or starting a fresh session. This assumes all keys, tokens, and 1Password items are already configured.

---

## Quick Setup (Copy & Paste)

### Step 1: Set Configuration Variables

**EDIT VALUES IF NEEDED** - Verify these match your project configuration:

```bash
# Your Information
export EMAIL=patrick.wm.meaney@gmail.com

# Project Naming
export PROJECT_DATE=011526
export SSH_KEY_NAME_HUMAN=id_ed25519_${PROJECT_DATE}_humanuser
export SSH_KEY_NAME_CICD=id_ed25519_${PROJECT_DATE}_cicd

# 1Password Configuration
export VAULT_1P=Z_Tech_ClicksAndCodes
export ITEM_1P="server011526-debian-ecom"

# 1Password Field Names
export FIELD_1P_DO_TOKEN=DOToken_FA_011526
export FIELD_1P_GH_TOKEN=GHPATCICD_RpoWkflo_WRDpckgs_011526

# Linux User Configuration
export LINUX_HUMAN_USERNAME=patDevOpsUser
export LINUX_BOTCICDGHA_USERNAME=ghaCICDBotUser
export LINUX_SERVER_NAME=server011526-debian-ecom
```

### Step 2: Export Terraform Variables from 1Password

**Run this in the same terminal session as Step 1:**

```bash
# Export DigitalOcean token
export DIGITALOCEAN_ACCESS_TOKEN=$(op item get ${ITEM_1P} --vault ${VAULT_1P} --fields label=${FIELD_1P_DO_TOKEN} --reveal)

# Export Terraform variables
export TF_VAR_LINUX_SERVER_NAME=$(op item get ${ITEM_1P} --vault ${VAULT_1P} --fields label=LINUX_SERVER_NAME)
export TF_VAR_LINUX_HUMAN_USERNAME=$(op item get ${ITEM_1P} --vault ${VAULT_1P} --fields label=LINUX_HUMAN_USERNAME)
export TF_VAR_LINUX_HUMAN_SSHKEY=$(op item get ${ITEM_1P} --vault ${VAULT_1P} --fields label=${SSH_KEY_NAME_HUMAN})
export TF_VAR_LINUX_BOTCICDGHA_USERNAME=$(op item get ${ITEM_1P} --vault ${VAULT_1P} --fields label=LINUX_BOTCICDGHA_USERNAME)
export TF_VAR_LINUX_CICDGHA_SSHKEY=$(op item get ${ITEM_1P} --vault ${VAULT_1P} --fields label=${SSH_KEY_NAME_CICD})
export TF_VAR_VAULT_1P=$(op item get ${ITEM_1P} --vault ${VAULT_1P} --fields label=VAULT_1P)
export TF_VAR_ITEM_1P=${ITEM_1P}
```

### Step 3: Verify Environment Variables

```bash
# Check that everything is set correctly
echo "DigitalOcean Token: ${DIGITALOCEAN_ACCESS_TOKEN:0:20}..." # Shows first 20 chars
echo "Server Name: $TF_VAR_LINUX_SERVER_NAME"
echo "Human Username: $TF_VAR_LINUX_HUMAN_USERNAME"
echo "CICD Username: $TF_VAR_LINUX_BOTCICDGHA_USERNAME"
echo "Human SSH Key: ${TF_VAR_LINUX_HUMAN_SSHKEY:0:50}..." # Shows first 50 chars
```

**Expected output:**
```
DigitalOcean Token: dop_v1_xxxxxxxxxxxxx...
Server Name: server011526-debian-ecom
Human Username: patDevOpsUser
CICD Username: ghaCICDBotUser
Human SSH Key: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxxxx...
```

---

## Now You're Ready

With these variables set, you can now run Terraform commands:

```bash
# Navigate to project directory
cd ~/localhost/projects/active/devops/server011526-debian-ecom

# Run Terraform
terraform plan
terraform apply
```

---

## Troubleshooting

### "Field not found" Error

```bash
[ERROR] "" isn't a field in the "server011526-debian-ecom" item
```

**Cause:** You didn't set the base configuration variables (Step 1) before trying to retrieve from 1Password.

**Fix:** Make sure you run **Step 1 first**, then Step 2.

### "Authentication required" Error

```bash
[ERROR] Authentication required
```

**Cause:** 1Password CLI not signed in.

**Fix:**
```bash
op signin
```

### Variable Not Set

```bash
echo $TF_VAR_LINUX_SERVER_NAME
# (empty output)
```

**Cause:** Either Step 1 or Step 2 wasn't run, or was run in a different terminal session.

**Fix:** Run both Step 1 and Step 2 in the same terminal session.

---

## Notes

- These environment variables only persist for the current terminal session
- If you open a new terminal tab/window, you'll need to run this again
- If you want these to persist, consider adding to `~/.zshrc` or `~/.bashrc` (but be careful with tokens!)
- The SSH keys are already in `~/.ssh/` and don't need to be regenerated