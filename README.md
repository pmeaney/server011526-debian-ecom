# server011526-debian-ecom

This is a Terraform project for my Debian-based ecommerce project, started approximately Jan 15, 2025.

It has evolved from my past TF project "server020325-debianNpm". 

## Getting started:

- For descriptive startup instructions with clarifying commentary: ./docs/initial-setup/setup-workflow-with-clarifications.md
- For quick, concise startup if you're already familiar with the project or its concepts: ./docs/initial-setup/setup-workflow-quick-and-concise.md
- If you're returning to the project after initial setup and, for example, need to reload env vars into your terminal session: ./docs/env-reload.md
- After the server is created with `terraform apply`, run through the verification steps in the doc ./docs/post-setup-verifications.md to ensure things were setup correctly

## Security Notes

This repository contains infrastructure-as-code for a linux server hosting a small business e-commerce marketplace. All sensitive information (tokens, keys, passwords, IP addresses) is managed via 1Password and environment variables - nothing sensitive is committed to this repository.

The server implements defense-in-depth: DigitalOcean cloud firewall restricts traffic to ports 80/443/22, UFW provides host-level firewall rules, fail2ban automatically blocks IPs after 3 failed SSH attempts, and SSH is configured for key-only authentication with password login disabled. 

**DevOps Overview:**
- Secrets management: 1Password CLI integration
- Infrastructure: Terraform for reproducible deployments
- Security: Multi-layered defense (cloud firewall, UFW, fail2ban, SSH key-only auth)

## Set up

This server runs a containerized web application stack on Debian 12. 

- Nginx Proxy Manager handles SSL certificates and routes traffic to applications

---