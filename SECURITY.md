# 🔒 N8N Security Guide

This document outlines security best practices for your n8n self-hosted deployment.

## 🚨 Critical Security Actions

### 1. Environment Variables Security
**Before starting your deployment:**

```bash
# Generate a strong encryption key (REQUIRED)
openssl rand -base64 32

# Create your .env file from template
cp env.template .env

# Edit .env file and update ALL passwords
nano .env
```

**⚠️ NEVER commit .env files to version control!**

### 2. Required Password Changes
Update these variables in your `.env` file:

```bash
# Change these immediately!
N8N_ENCRYPTION_KEY=your-strong-32-char-encryption-key
N8N_BASIC_AUTH_PASSWORD=your-strong-password
POSTGRES_PASSWORD=your-strong-db-password
REDIS_PASSWORD=your-strong-redis-password
```

### 3. User Management (Production)
For production deployments, disable basic auth and enable proper user management:

```bash
# In .env file
N8N_BASIC_AUTH_ACTIVE=false
N8N_USER_MANAGEMENT_DISABLED=false
```

## 🛡️ Network Security

### Docker Network Isolation
The production configuration uses a custom Docker network:

```yaml
networks:
  n8n-network:
    driver: bridge
```

This isolates your n8n services from other Docker containers.

### Reverse Proxy Setup
For production, use a reverse proxy with HTTPS:

```nginx
# nginx configuration example
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🔐 Data Protection

### Encryption Key Management
- **Never lose your encryption key** - all credentials become unrecoverable
- Store the key securely (password manager, vault system)
- Consider key rotation strategy for long-term deployments

### Database Security
```bash
# PostgreSQL security settings
POSTGRES_PASSWORD=strong-unique-password
POSTGRES_INITDB_ARGS="--encoding=UTF-8 --lc-collate=en_US.UTF-8 --lc-ctype=en_US.UTF-8"
```

### Backup Encryption
```bash
# Encrypt backups before storage
docker-compose exec postgres pg_dump -U n8n n8n | \
  gpg --symmetric --cipher-algo AES256 --output backup_$(date +%Y%m%d).sql.gpg
```

## 🚪 Access Control

### Firewall Configuration
```bash
# UFW example - only allow necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (redirect to HTTPS)
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Block direct access to n8n port if using reverse proxy
sudo ufw deny 5678/tcp
```

### SSH Security
```bash
# Disable password authentication
# Edit /etc/ssh/sshd_config
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
```

## 📊 Monitoring & Auditing

### Log Management
```bash
# In .env file
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=console

# Centralized logging setup
docker-compose logs -f --tail=100 n8n | \
  logger -t n8n-app
```

### Health Monitoring
All services include health checks. Monitor them:

```bash
# Check health status
docker-compose ps

# Set up alerting for service failures
#!/bin/bash
if ! docker-compose ps | grep -q "healthy"; then
    echo "N8N service unhealthy!" | mail -s "Alert" admin@yourcompany.com
fi
```

## 🔄 Updates & Maintenance

### Security Updates
```bash
# Regular update schedule
#!/bin/bash
# update_n8n.sh
docker-compose pull
docker-compose down
docker-compose up -d
docker system prune -f
```

### Vulnerability Scanning
```bash
# Scan Docker images for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image docker.n8n.io/n8nio/n8n:1.104.0
```

## ⚠️ Security Checklist

### Pre-Production
- [ ] All default passwords changed
- [ ] Strong encryption key generated
- [ ] .env file not in version control
- [ ] .gitignore configured correctly
- [ ] Network isolation configured
- [ ] Resource limits set

### Production Deployment
- [ ] HTTPS configured with valid certificate
- [ ] Basic auth disabled
- [ ] User management enabled
- [ ] Firewall rules configured
- [ ] Backup strategy implemented
- [ ] Monitoring system setup
- [ ] Log aggregation configured

### Ongoing Maintenance
- [ ] Regular security updates
- [ ] Backup verification
- [ ] Access review
- [ ] Log monitoring
- [ ] Performance monitoring
- [ ] Vulnerability scanning

## 🆘 Incident Response

### Data Breach Response
1. **Immediate Actions:**
   - Isolate affected systems
   - Change all passwords immediately
   - Revoke API keys and tokens
   - Generate new encryption key (if not compromised)

2. **Assessment:**
   - Check access logs
   - Identify compromised workflows
   - Assess data exposure

3. **Recovery:**
   - Restore from clean backups
   - Update security configurations
   - Implement additional monitoring

### Emergency Contacts
- Security Team: [your-security-team@company.com]
- System Administrator: [your-admin@company.com]
- n8n Support: [community.n8n.io](https://community.n8n.io)

## 📚 Additional Resources

- [n8n Security Documentation](https://docs.n8n.io/hosting/security/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/security.html)
- [Redis Security](https://redis.io/docs/management/security/)

---

**Remember: Security is an ongoing process, not a one-time setup!** 