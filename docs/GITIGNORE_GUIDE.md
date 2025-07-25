# 📝 .gitignore Guide for n8n Project

This document explains the comprehensive `.gitignore` file for the n8n automation project.

## 🎯 **Why This Matters:**

A proper `.gitignore` prevents sensitive data, temporary files, and system-generated content from being committed to version control.

## 🔒 **Critical Security Categories:**

### **🚨 Never Commit These (Security Risk):**

```bash
# Environment files (contain passwords, API keys)
.env
.env.production
.env.local
*.env.backup.*

# n8n user data (contains workflow credentials)
.n8n/
n8n_data/

# Database dumps (may contain sensitive data)
*.sql
backup*.sql
n8n-backup*/

# SSL certificates and private keys
*.pem
*.key
*.crt
nginx/ssl/
certbot/
letsencrypt/
```

### **📊 Performance & Storage Categories:**

```bash
# Data directories (large, regeneratable)
.data/
data/
postgres_data/
redis_data/

# Logs (grows large over time)
*.log
logs/
nginx/logs/

# Temporary files
*.tmp
*.temp
temp/
```

### **🛠️ Development & System Categories:**

```bash
# Editor/IDE files
.vscode/
.idea/
*.swp

# OS generated files  
.DS_Store      # macOS
Thumbs.db      # Windows
*~             # Linux

# Docker customizations
docker-compose.override.yml
docker-compose.local.yml
```

## 📋 **File Categories Explained:**

### **1. Environment & Configuration**
```bash
# What: Environment variables, API keys, passwords
# Why: Contains sensitive credentials
# Example: POSTGRES_PASSWORD=secret123
.env
.env.*
```

### **2. n8n Data & Workflows** 
```bash
# What: n8n's internal data, workflow credentials
# Why: Contains encrypted passwords and API tokens
# Location: ~/.n8n/ directory
.n8n/
n8n_data/
```

### **3. Database & Storage**
```bash
# What: PostgreSQL data files, Redis dumps
# Why: Large files, can be regenerated
# Location: Docker volumes
.data/
postgres_data/
redis_data/
```

### **4. SSL Certificates**
```bash
# What: SSL certificates, private keys
# Why: Security risk if exposed, can be regenerated
# Example: Let's Encrypt certificates
*.pem
*.key
certbot/
```

### **5. Logs & Monitoring**
```bash
# What: Application logs, access logs
# Why: Large files, contains runtime data only
# Example: nginx access logs
*.log
logs/
nginx/logs/
```

## ✅ **What IS Committed:**

### **Safe Configuration Files:**
```bash
# Template files (no sensitive data)
env.template
setup-simple.env

# Docker configurations
docker-compose.yml
docker-compose.prod.yml

# Documentation
README.md
docs/
workflows/jira-teams-automation.json  # No credentials in template
```

### **Scripts & Tools:**
```bash
# Setup scripts
scripts/enable-user-management.sh
scripts/setup-nginx.sh
scripts/setup-entra-id.sh

# Configuration templates
nginx/nginx.conf
```

## 🔍 **Checking What's Ignored:**

### **View Ignored Files:**
```bash
# See all ignored files
git status --ignored

# Check specific file
git check-ignore -v .env

# See what would be added
git add --dry-run .
```

### **Force Add If Needed:**
```bash
# Override .gitignore for specific file
git add -f some-ignored-file.txt

# Add template files (already allowed)
git add env.template
```

## 🚨 **Security Checklist:**

Before committing, always verify:

```bash
# 1. Check no .env files are being committed
git diff --cached | grep -E "\.env|password|secret|key"

# 2. Verify no sensitive data in staged files
git diff --cached

# 3. Check file sizes (avoid large data files)
git diff --cached --stat

# 4. Review what's being committed
git status
```

## 🛠️ **Customization:**

### **Local Overrides:**
Create `.gitignore.local` for additional local ignores:
```bash
# Local development files
my-local-scripts/
*.local.sh
```

### **Project-Specific Additions:**
Add to main `.gitignore` for project needs:
```bash
# Company-specific
company-configs/
internal-docs/

# Tool-specific
.terraform/
kubernetes-secrets/
```

## 📚 **Best Practices:**

### **✅ DO:**
- Review `.gitignore` regularly
- Use `git status` before committing
- Add comments to explain why files are ignored
- Use specific patterns over wildcards when possible

### **❌ DON'T:**
- Commit `.env` files (even accidentally)
- Ignore legitimate code files
- Use overly broad patterns like `*`
- Commit large data files or logs

### **🔧 Maintenance:**
```bash
# Clean up already-tracked files that should be ignored
git rm --cached .env
git rm -r --cached .n8n/

# Update .gitignore and commit
git add .gitignore
git commit -m "Update .gitignore to exclude sensitive files"
```

---

## 🎯 **Quick Reference:**

| Category | Examples | Reason |
|----------|----------|---------|
| **Secrets** | `.env`, `.n8n/` | Security risk |
| **Data** | `postgres_data/`, `*.sql` | Large, regeneratable |
| **Logs** | `*.log`, `logs/` | Large, temporary |
| **System** | `.DS_Store`, `.vscode/` | Environment-specific |
| **Temp** | `*.tmp`, `temp/` | Temporary files |

**Remember:** When in doubt, don't commit it. You can always add files later with `git add -f` if needed.

---

**🔒 Security First:** This `.gitignore` prioritizes security by preventing accidental exposure of credentials and sensitive data. 