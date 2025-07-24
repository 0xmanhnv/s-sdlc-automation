# 📜 n8n Management Scripts

This directory contains useful scripts to help you manage your n8n installation.

## Available Scripts

### 🔧 `enable-user-management.sh`
**Interactive setup for multi-user environment**

```bash
./scripts/enable-user-management.sh
```

**What it does:**
- Guides you through user management configuration
- Generates secure passwords and encryption keys
- Configures email settings for user invitations
- Sets up owner account
- Updates .env file with proper settings

**When to use:**
- Setting up n8n for multiple users
- Migrating from basic auth to user management
- Initial production deployment

---

### 🔐 `setup-entra-id.sh`
**Microsoft Entra ID (Azure AD) SAML integration setup**

```bash
./scripts/setup-entra-id.sh
```

**What it does:**
- Configures SAML SSO with Microsoft Entra ID
- Sets up role mapping from Azure AD groups to n8n roles
- Configures domain and SSL settings
- Updates environment variables for SAML
- Provides Azure AD configuration summary

**When to use:**
- Enterprise environments using Microsoft Entra ID
- Setting up Single Sign-On (SSO)
- Implementing role-based access control with Azure AD groups
- Migration from basic auth to enterprise authentication

**Prerequisites:**
- Azure AD Premium license
- Enterprise Application created in Azure AD
- SSL certificate configured
- Domain name pointing to n8n server

---

### 🌐 `setup-nginx.sh`
**Nginx reverse proxy with SSL/TLS setup**

```bash
./scripts/setup-nginx.sh
```

**What it does:**
- Configures nginx reverse proxy for n8n
- Sets up automatic SSL certificates with Let's Encrypt
- Handles HTTP to HTTPS redirects
- Configures security headers and rate limiting
- Supports both production (SSL) and development (HTTP) modes

**When to use:**
- Production deployments requiring HTTPS
- Setting up domain-based access to n8n
- Implementing security best practices
- SAML/Entra ID integration (requires HTTPS)

**Prerequisites:**
- Domain name pointing to your server
- Ports 80 and 443 accessible
- Valid email address for SSL certificates

---

## Usage Tips

### Make scripts executable
```bash
chmod +x scripts/*.sh
```

### Run from project root
```bash
# From /path/to/n8n/ directory
./scripts/enable-user-management.sh
```

### Backup before running
Scripts will automatically backup your .env file, but it's good practice to backup your entire setup:

```bash
# Backup data
docker-compose exec postgres pg_dump -U n8n n8n > backup_$(date +%Y%m%d).sql

# Backup configuration
cp -r . ../n8n-backup-$(date +%Y%m%d)/
```

## Script Development

### Adding new scripts
1. Create script file with `.sh` extension
2. Add shebang: `#!/bin/bash`
3. Set proper error handling: `set -e`
4. Make executable: `chmod +x script-name.sh`
5. Document in this README

### Testing scripts
Always test scripts in a development environment before production use.

### Contributing
Feel free to contribute useful automation scripts for common n8n management tasks. 