# Nginx Proxy Manager Deployment Guide

## Prerequisites

Ensure rsync is installed on both your laptop and the remote server:

```bash
# on MacOS
brew install rsync

# On Debian/Ubuntu 
# !! NOTE: Our Terraform project already installs this as shown in the tf-cloud-config.yml
sudo apt install rsync -y
```

## Deploy NPM Files to Server

Transfer the NPM configuration directory to your server:

```bash
# Using direct SSH connection
rsync -avvz ./nginxProxyMgr/ user@ip:~/nginxProxyMgr

# Or using SSH config alias (if you have a Host "deb" configured in ~/.ssh/config)
rsync -avvz ./nginxProxyMgr/ deb:~/nginxProxyMgr
```

## Start NPM Containers

### Interactive Mode (with live logs)

Useful for initial setup and debugging:

```bash
cd ~/nginxProxyMgr && docker compose up
```

Press `Ctrl+C` to stop.

### Background Mode (detached)

Run containers in the background and tail logs:

```bash
cd ~/nginxProxyMgr && \
docker compose up -d --build --remove-orphans && \
docker compose logs -f nginx-proxy-mgr-011526
```

Press `Ctrl+C` to exit logs (containers keep running).

### View Logs Later

```bash
cd ~/nginxProxyMgr && docker compose logs -f nginx-proxy-mgr-011526

# Or view both containers (NPM + Postgres)
cd ~/nginxProxyMgr && docker compose logs -f
```

## Access NPM Admin Panel

Navigate to the admin interface (use HTTP, not HTTPS):

```
http://yourServerIP:81
```

**Default credentials:**
- Username: `admin@example.com`
- Password: `changeme`

⚠️ **Change these immediately after first login!**

## SSL Certificate Setup

1. Register a domain name with a registrar
2. Configure DNS A-Records pointing to your server's IP
3. In NPM admin panel, add SSL certificates for your domains
4. Create proxy hosts pointing to your applications

## Environment Variables

This deployment uses a `.env--nginx-proxy-mgr` file for configuration. Create this file in the `nginxProxyMgr/` directory with:

```bash
# Postgres Configuration
DB_POSTGRES_HOST=postgres-for-nginx-proxy-mgr-011526
DB_POSTGRES_PORT=5432
DB_POSTGRES_USER=npm
DB_POSTGRES_PASSWORD=your_secure_password_here
DB_POSTGRES_NAME=npm

# Postgres Environment Variables
POSTGRES_USER=npm
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=npm

# Uncomment if IPv6 is not enabled on your host
# DISABLE_IPV6=true
```

**Important:** Use the same password for both `DB_POSTGRES_PASSWORD` and `POSTGRES_PASSWORD`.

## Quick Reference

```bash
# Deploy/update NPM config
rsync -avvz ./nginxProxyMgr/ deb:~/nginxProxyMgr

# Start in background
cd ~/nginxProxyMgr && docker compose up -d

# View logs
cd ~/nginxProxyMgr && docker compose logs -f

# Stop containers
cd ~/nginxProxyMgr && docker compose down

# Restart containers
cd ~/nginxProxyMgr && docker compose restart

# Rebuild and restart
cd ~/nginxProxyMgr && docker compose up -d --build --force-recreate
```

## Container Information

**Services:**
- `nginx-proxy-mgr-011526` - Main NPM application
- `postgres-for-nginx-proxy-mgr-011526` - PostgreSQL database

**Ports:**
- `80` - Public HTTP
- `443` - Public HTTPS
- `81` - Admin panel

**Volumes:**
- `./data` - NPM application data
- `./letsencrypt` - SSL certificates
- `./postgres` - PostgreSQL data

**Network:**
- `main-network--npm011526` - Internal Docker network

## Troubleshooting

### Check container status
```bash
cd ~/nginxProxyMgr && docker compose ps
```

### View container logs
```bash
# NPM logs
cd ~/nginxProxyMgr && docker compose logs nginx-proxy-mgr-011526

# Postgres logs
cd ~/nginxProxyMgr && docker compose logs postgres-for-nginx-proxy-mgr-011526
```

### Restart a specific service
```bash
cd ~/nginxProxyMgr && docker compose restart nginx-proxy-mgr-011526
```

### Remove everything and start fresh
```bash
cd ~/nginxProxyMgr && docker compose down -v
# WARNING: This deletes all data including SSL certificates!
```

## Project Structure

```
nginxProxyMgr/
├── docker-compose.yml
├── .env--nginx-proxy-mgr    # You need to create this
├── data/                     # Created by Docker Compose (NPM data)
├── letsencrypt/              # Created by Docker Compose (SSL certificates)
└── postgres/                 # Created by Docker Compose (PostgreSQL data)
```