# n8n Self-Hosted Setup

Simple, production-ready n8n deployment with PostgreSQL.

## 🚀 Quick Start (5 minutes)

### 1. Clone & Setup
```bash
git clone <your-repo>
cd n8n

# Copy environment template  
cp setup-simple.env .env
```

### 2. Configure Passwords
```bash
# Edit .env file and change:
nano .env

# Required changes:
N8N_ENCRYPTION_KEY=your-32-character-key-here  # Generate: openssl rand -base64 32
POSTGRES_PASSWORD=your-strong-database-password
```

### 3. Start n8n
```bash
docker-compose -f docker-compose.simple.yml up -d
```

### 4. Access n8n
Open http://localhost:5678 and create your first user.

**That's it! 🎉**

---

## 🔧 Common Configurations

### 🌐 **Use Custom Domain**
Update `.env`:
```bash
N8N_HOST=n8n.yourcompany.com
N8N_PROTOCOL=https  
WEBHOOK_URL=https://n8n.yourcompany.com
```

### 👥 **Multiple Users**
n8n automatically supports multiple users. Just create accounts through the web interface.

### 🔒 **Enterprise SSO (Advanced)**
For SAML/Azure AD integration, see the advanced setup files:
- `docker-compose.nginx.yml` - With SSL support
- `docs/ENTRA_ID_INTEGRATION.md` - SAML setup guide

---

## 📊 Maintenance

### **View Logs**
```bash
docker-compose -f docker-compose.simple.yml logs -f
```

### **Backup Data**
```bash
# Backup database
docker-compose -f docker-compose.simple.yml exec postgres pg_dump -U n8n n8n > backup.sql

# Backup n8n data  
docker cp $(docker-compose -f docker-compose.simple.yml ps -q n8n):/home/node/.n8n ./n8n-backup
```

### **Update n8n**
```bash
docker-compose -f docker-compose.simple.yml pull
docker-compose -f docker-compose.simple.yml down
docker-compose -f docker-compose.simple.yml up -d
```

---

## 🆘 Troubleshooting

**Port already in use?**
```bash
# Change port in .env
N8N_PORT=8080
```

**Can't access from other machines?**
```bash
# Set your server IP in .env
N8N_HOST=192.168.1.100
WEBHOOK_URL=http://192.168.1.100:5678
```

**Database connection failed?**
```bash
# Check if database is running
docker-compose -f docker-compose.simple.yml ps postgres
```

---

## 📚 Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Community Forum](https://community.n8n.io/)

### Advanced Setups (if you need them)
- `docker-compose.nginx.yml` - Production with SSL
- `docs/USER_MANAGEMENT.md` - Advanced user management
- `docs/ENTRA_ID_INTEGRATION.md` - Enterprise SSO

---

**Keep it simple!** This setup handles 90% of n8n use cases. Only use advanced configurations if you specifically need them. 