# N8N Self-Hosted Setup

Production-ready n8n workflow automation platform with PostgreSQL and Redis.

## 🏗️ Architecture

This setup includes:
- **n8n**: Workflow automation platform
- **PostgreSQL 16**: Primary database for workflows and credentials
- **Redis 7**: Queue management and caching
- **Docker Compose**: Container orchestration

## 🚀 Quick Start

### Prerequisites
- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 2GB RAM
- 10GB disk space

### 1. Clone and Setup
```bash
git clone <your-repo-url>
cd n8n
```

### 2. Configure Environment
```bash
# Copy environment template
cp env.template .env

# Generate encryption key
openssl rand -base64 32

# Edit .env file with your settings
nano .env
```

### 3. Start Services
```bash
# Production with nginx + SSL (Recommended)
./scripts/setup-nginx.sh

# Or production without nginx
docker-compose -f docker-compose.prod.yml up -d

# Or development setup
docker-compose up -d
```

### 4. Access n8n
Open http://localhost:5678 in your browser.

## 👥 User Management Setup

For multi-user environments, enable user management instead of basic auth:

### Quick Setup (Recommended)
```bash
# Run the interactive setup script
./scripts/enable-user-management.sh
```

### Manual Setup
1. Update your `.env` file:
```bash
N8N_BASIC_AUTH_ACTIVE=false
N8N_USER_MANAGEMENT_DISABLED=false
N8N_OWNER_EMAIL=admin@yourcompany.com
N8N_OWNER_PASSWORD=your-secure-password
```

2. Restart services:
```bash
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

3. Access n8n and complete owner account setup

📚 **See [User Management Guide](./docs/USER_MANAGEMENT.md) for complete documentation**

## 🔐 Enterprise Authentication

For enterprise environments, n8n supports Microsoft Entra ID (Azure AD) integration:

### Microsoft Entra ID Setup
```bash
# Run the Entra ID setup script
./scripts/setup-entra-id.sh
```

**Features:**
- ✅ SAML 2.0 Single Sign-On (SSO)
- ✅ Automatic user provisioning from Azure AD
- ✅ Role mapping: Azure AD Groups → n8n Roles
- ✅ Group-based access control
- ✅ Just-in-Time (JIT) provisioning

📚 **See [Entra ID Integration Guide](./docs/ENTRA_ID_INTEGRATION.md) for detailed setup**

## 🌐 Production Deployment with Nginx

For production environments, especially when using SAML/Entra ID, nginx reverse proxy is **HIGHLY RECOMMENDED**:

### Why Nginx?
- ✅ **SSL/TLS Termination** - Automatic HTTPS with Let's Encrypt
- ✅ **Security Headers** - XSS protection, HSTS, CSP
- ✅ **Rate Limiting** - DDoS protection and API throttling
- ✅ **WebSocket Support** - Proper handling for n8n editor
- ✅ **SAML Compatibility** - Required for enterprise SSO

### Quick Setup
```bash
# Setup nginx with automatic SSL
./scripts/setup-nginx.sh
```

**When to use Nginx:**
- 🏢 **Production deployments**
- 🔐 **SAML/Entra ID integration** (HTTPS required)
- 🌐 **Custom domain access**
- 🛡️ **Enhanced security requirements**
- ⚡ **Performance optimization**

**Deployment Options:**
- `docker-compose.yml` - Basic setup (development)
- `docker-compose.prod.yml` - Production without nginx
- `docker-compose.nginx.yml` - Production with nginx + SSL

## 🔒 Security Best Practices

### ✅ Implemented
- [x] Environment variables for sensitive data
- [x] Strong encryption key requirement
- [x] Password-protected Redis
- [x] Health checks for all services
- [x] Resource limits
- [x] Custom Docker network
- [x] Named volumes for data persistence
- [x] Timezone configuration

### 🔧 Required Configuration
1. **Change default passwords** in `.env` file
2. **Generate encryption key**: `openssl rand -base64 32`
3. **Set strong database password**
4. **Configure timezone** for your region
5. **Set proper domain** for production webhooks

### 🚨 Production Checklist
- [ ] **Set up nginx reverse proxy:** `./scripts/setup-nginx.sh`
- [ ] **Configure SSL certificates** (automatic with Let's Encrypt)
- [ ] **Disable basic auth, enable user management**
- [ ] **Consider enterprise SSO** (Entra ID/SAML) for organizations
- [ ] **Set up backup strategy** for PostgreSQL and n8n data
- [ ] **Configure monitoring and logging**
- [ ] **Implement firewall rules** (ports 80, 443 only)
- [ ] **Use environment variables** for sensitive data
- [ ] **Regular security updates and backups**
- [ ] **Test disaster recovery procedures**

## 📊 Monitoring & Maintenance

### Health Checks
All services include health checks:
```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs -f n8n
```

### Backup Strategy
```bash
# Backup PostgreSQL data
docker-compose exec postgres pg_dump -U n8n n8n > backup_$(date +%Y%m%d).sql

# Backup n8n data
docker-compose exec n8n tar -czf /tmp/n8n_backup.tar.gz /home/node/.n8n
docker cp $(docker-compose ps -q n8n):/tmp/n8n_backup.tar.gz ./n8n_backup_$(date +%Y%m%d).tar.gz
```

### Updates
```bash
# Update to latest version
docker-compose pull
docker-compose down
docker-compose up -d
```

## 🔧 Configuration

### Environment Variables
Key settings in `.env`:

| Variable | Description | Required |
|----------|-------------|----------|
| `N8N_ENCRYPTION_KEY` | 32+ char encryption key | ✅ |
| `POSTGRES_PASSWORD` | Database password | ✅ |
| `REDIS_PASSWORD` | Redis password | ✅ |
| `GENERIC_TIMEZONE` | Your timezone | ✅ |
| `WEBHOOK_URL` | Public webhook URL | Production |

### Performance Tuning
- **Memory**: Adjust resource limits in docker-compose.prod.yml
- **Executions**: Configure `EXECUTIONS_DATA_MAX_AGE` for cleanup
- **Redis**: Enable for queue management in high-load scenarios

## 🛠️ Development vs Production

### Development (docker-compose.yml)
- Basic configuration
- Simplified setup
- Local development focused

### Production (docker-compose.prod.yml)
- Health checks
- Resource limits
- Security hardening
- Performance optimization

## 📚 References

- [n8n Docker Documentation](https://docs.n8n.io/hosting/installation/docker)
- [n8n Hosting Examples](https://github.com/n8n-io/n8n-hosting)
- [Security Best Practices](https://docs.n8n.io/hosting/security/)
- [User Management Guide](./docs/USER_MANAGEMENT.md) - Comprehensive guide for multi-user setup
- [Entra ID Integration Guide](./docs/ENTRA_ID_INTEGRATION.md) - Microsoft Azure AD SAML SSO setup

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- [n8n Community Forum](https://community.n8n.io/)
- [n8n Documentation](https://docs.n8n.io/)
- [GitHub Issues](https://github.com/n8n-io/n8n/issues)

---

**⚠️ Important**: Always use the production configuration (`docker-compose.prod.yml`) for production deployments.
