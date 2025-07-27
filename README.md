# n8n Environment

Môi trường n8n được tối ưu hóa với reverse proxy, SSL, và queue system.

## 🚀 Tính năng

- ✅ **n8n Main Instance** - Command center cho automation
- ✅ **PostgreSQL Database** - Persistent data storage
- ✅ **Redis Queue** - Distributed task processing
- ✅ **Nginx Reverse Proxy** - Load balancing và SSL termination
- ✅ **SSL Certificates** - Tự động với Let's Encrypt
- ✅ **Health Checks** - Monitoring cho tất cả services
- ✅ **Auto HTTP/HTTPS** - Tự động detect mode

## 📋 Yêu cầu

- Docker & Docker Compose
- 2GB RAM minimum (4GB recommended)
- 10GB disk space
- Domain name (cho production SSL)

## 🛠️ Cài đặt

### 1. Clone repository
```bash
git clone <repository-url>
cd s-sdlc-automation
```

### 2. Cấu hình môi trường
```bash
# Development nhanh (có giá trị mặc định)
cp env.example .env

# Hoặc Production đầy đủ (cần cấu hình thêm)
cp env.template .env

# Chỉnh sửa các thông số cần thiết
nano .env
```

### 3. Khởi động môi trường
```bash
# Development (localhost) - HTTP mode
docker-compose up -d

# Production với SSL
./scripts/setup-ssl.sh

# Hoặc manual
docker-compose up -d

# Với logs
docker-compose up
```

## 🌐 Truy cập

### Development (localhost)
- **n8n UI:** http://localhost
- **Direct n8n:** http://localhost:5678
- **Health Check:** http://localhost/health

### Production (với domain)
```bash
# Setup SSL cho domain (interactive)
./scripts/setup-ssl.sh

# Hoặc manual setup
# 1. Set N8N_HOST=yourdomain.com in .env
# 2. docker-compose up -d

# Truy cập
https://yourdomain.com
```

## 🔧 Cấu hình

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_USER` | Database username | `n8n` |
| `POSTGRES_PASSWORD` | Database password | `n8n_secure_password_2024` |
| `REDIS_PASSWORD` | Redis password | `redis_secure_password_2024` |
| `N8N_HOST` | Domain name | `localhost` |
| `N8N_ENCRYPTION_KEY` | Encryption key | `your-super-secret-encryption-key-32-chars-long` |
| `SSL_EMAIL` | Email for SSL certificates | `admin@localhost` |

### Ports

| Service | Port | Description |
|---------|------|-------------|
| nginx | 80 | HTTP |
| nginx | 443 | HTTPS |
| n8n | 5678 | Direct access |

## 🔍 Monitoring

### Health Checks
```bash
# Kiểm tra trạng thái services
docker-compose ps

# Health check nginx
curl http://localhost/health

# Health check n8n
curl http://localhost:5678/healthz
```

### Logs
```bash
# Tất cả services
docker-compose logs

# Service cụ thể
docker-compose logs n8n
docker-compose logs nginx
docker-compose logs postgres
```

## 🔒 Security

### Container Management
- ✅ Health checks for monitoring
- ✅ Auto-restart policies
- ✅ Volume persistence
- ✅ Network isolation

### Network Security
- ✅ Internal network isolation
- ✅ SSL/TLS encryption (production)
- ✅ Security headers
- ✅ Rate limiting

## 🚨 Troubleshooting

### Permission Issues
```bash
# Quick fix - Restart with proper permissions
./scripts/setup-permissions.sh
docker-compose up -d
```

### SSL Issues
```bash
# Check nginx logs
docker logs n8n_nginx

# Manual SSL setup
./scripts/setup-ssl.sh
```

### Database Issues
```bash
# Reset database
docker-compose down -v
docker-compose up -d
```

## 📊 Performance

### Resource Usage
- **PostgreSQL:** ~512MB RAM
- **Redis:** ~256MB RAM  
- **n8n:** ~1GB RAM
- **Nginx:** ~128MB RAM

### Scaling
```bash
# Scale n8n service (if needed)
# Note: Current setup uses single n8n instance with Redis queue
# For scaling, consider using n8n worker mode in production
docker-compose up -d
```

## 🔄 Maintenance

### Updates
```bash
# Update n8n version
export N8N_VERSION=1.105.0
docker-compose up -d --force-recreate
```

### Backups
```bash
# Database backup
docker exec n8n_postgres pg_dump -U n8n n8n > backup.sql

# Restore
docker exec -i n8n_postgres psql -U n8n n8n < backup.sql
```

## 📝 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

- **Issues:** GitHub Issues
- **Documentation:** This README
- **Community:** n8n Community Forum
