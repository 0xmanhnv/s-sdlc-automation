# 🐳 Docker Compose Usage Guide

## 📋 **Optimized Structure (3 Files)**

After careful consideration and user feedback, we have **3 SPECIALIZED FILES** for different use cases:

```
├── docker-compose.yml          # 🔧 Development (Default)
├── docker-compose.prod.yml     # 🏭 Production + Scaling
└── docker-compose.devsecops.yml # 🔒 DevSecOps (Ready-to-Deploy)
```

## 🤔 **Why 3 Files? User Feedback Integration**

### **❌ Initial Mistake**: 
I tried to consolidate DevSecOps into production with console scaling commands, but **user correctly pointed out** this creates poor UX for security teams.

### **✅ User's Valid Concerns**:
- DevSecOps teams need **one-command deployment**: `docker-compose -f docker-compose.devsecops.yml up -d`
- Should not memorize scaling parameters: `--scale n8n-worker=2`
- Security teams have **different identity** and requirements than generic production

### **✅ Final Solution - 3 Specialized Files**:

| File | Purpose | Target Users | Usage |
|------|---------|--------------|-------|
| **Development** | Local dev, testing | Developers | `docker-compose up -d` |
| **Production** | General prod, flexible scaling | DevOps teams | `docker-compose -f docker-compose.prod.yml up -d` |
| **DevSecOps** | Security automation, pre-configured | Security teams | `docker-compose -f docker-compose.devsecops.yml up -d` |

---

## 🔧 **Development Usage (Default)**

### **Quick Start**
```bash
# Uses docker-compose.yml automatically  
docker-compose up -d

# Access: http://localhost:5678
```

### **Features:**
- ✅ **Minimal Setup**: PostgreSQL + n8n only (2 services)
- ✅ **Fast Startup**: No SSL, Redis complexity
- ✅ **Debug Mode**: Verbose logging for development
- ✅ **Direct Access**: Port 5678 exposed
- ✅ **Development Optimized**: Quick iteration workflow

---

## 🏭 **Production Usage (Flexible)**

### **Single Instance (Default)**
```bash
# Standard production deployment
docker-compose -f docker-compose.prod.yml up -d

# Access: https://your-domain.com
```

### **Dynamic Scaling (DevOps Teams)**
```bash
# Scale with 2 workers for higher load
docker-compose -f docker-compose.prod.yml up -d --scale n8n-worker=2

# Scale with 4 workers for enterprise load
docker-compose -f docker-compose.prod.yml up -d --scale n8n-worker=4

# Remove workers when load decreases
docker-compose -f docker-compose.prod.yml up -d --scale n8n-worker=0
```

### **Features:**
- ✅ **Complete Stack**: PostgreSQL + Redis + n8n + Nginx + SSL (5 services)
- ✅ **Flexible Scaling**: Scale workers on-demand
- ✅ **Production Security**: SSL, resource limits, health checks
- ✅ **DevOps Friendly**: Manual control over scaling

---

## 🔒 **DevSecOps Usage (Specialized)**

### **One-Command Deployment**
```bash
# Security team deployment - everything pre-configured
docker-compose -f docker-compose.devsecops.yml up -d

# Access: https://your-domain.com
# Workers: Pre-configured 2 workers ready for SAST automation
```

### **Features:**
- ✅ **Pre-configured Workers**: 1 Main + 2 Workers (3 n8n instances)
- ✅ **DevSecOps Identity**: Container names like `n8n_devsecops_*`
- ✅ **Security Optimized**: Debug logging, queue mode forced on
- ✅ **Ready for SAST**: Built for parallel security workflow processing
- ✅ **No Manual Scaling**: Workers always available for security automation
- ✅ **Team Workflow**: Security teams don't need DevOps knowledge

### **DevSecOps Architecture:**
```
🔒 DevSecOps Stack (7 services):
├── n8n_app        # Main instance (UI + webhooks)
├── n8n_worker_1   # SAST processing worker
├── n8n_worker_2   # Security automation worker  
├── n8n_postgres   # Database with 1GB memory
├── n8n_redis      # Queue with 1GB memory
├── n8n_nginx      # Reverse proxy
└── n8n_certbot    # SSL management
```

---

## 📊 **Resource Comparison**

| Setup | Services | Memory | CPU | Use Case |
|-------|----------|--------|-----|----------|
| **Development** | 2 | ~1GB | Low | Local development |
| **Production (Single)** | 5 | ~2GB | Medium | Small-medium production |
| **Production (Scaled)** | 5-9 | ~4-6GB | High | Large production with scaling |
| **DevSecOps** | 7 | ~6GB | High | Security automation (fixed setup) |

---

## 🎯 **When to Use Which File?**

### **🔧 Use Development (`docker-compose.yml`):**
- Local development and testing
- Quick prototyping of workflows  
- Learning n8n functionality
- No SSL or production features needed

### **🏭 Use Production (`docker-compose.prod.yml`):**
- General production deployments
- Need flexible worker scaling
- DevOps teams managing infrastructure
- Variable load patterns requiring manual scaling

### **🔒 Use DevSecOps (`docker-compose.devsecops.yml`):**
- Security teams focused on automation
- SAST integration and security workflows  
- Need consistent, always-available workers
- Want one-command deployment without scaling complexity
- Security-focused identity and monitoring

---

## 💡 **Best Practices by Use Case**

### **👨‍💻 Developers:**
```bash
# Always use default for development
docker-compose up -d

# For testing production features locally
docker-compose -f docker-compose.prod.yml up -d
```

### **🏢 DevOps Teams:**
```bash
# Start with single instance
docker-compose -f docker-compose.prod.yml up -d

# Monitor load and scale as needed
docker-compose -f docker-compose.prod.yml up -d --scale n8n-worker=N

# Use Redis queue script for optimization
./scripts/setup-queue-redis.sh
```

### **🔒 Security Teams:**
```bash
# One command for full DevSecOps setup
docker-compose -f docker-compose.devsecops.yml up -d

# Import security workflows
cp workflows/jira_sast_security_review_workflow.json /path/to/n8n/

# Monitor security automation
docker-compose -f docker-compose.devsecops.yml logs -f n8n-worker-1
```

---

## 🔄 **Migration Between Setups**

### **Development → Production:**
```bash
# Stop dev environment  
docker-compose down

# Start production (same data volumes)
docker-compose -f docker-compose.prod.yml up -d
```

### **Production → DevSecOps:**
```bash
# Stop production
docker-compose -f docker-compose.prod.yml down

# Start DevSecOps (same data volumes)
docker-compose -f docker-compose.devsecops.yml up -d
```

### **DevSecOps → Production (with scaling):**
```bash
# Stop DevSecOps
docker-compose -f docker-compose.devsecops.yml down

# Start production with equivalent workers
docker-compose -f docker-compose.prod.yml up -d --scale n8n-worker=2
```

---

## 🚨 **User Feedback Integration**

### **✅ What User Correctly Identified:**
1. **DevSecOps teams need dedicated files** - not console scaling
2. **One-command deployment** is crucial for security team workflows
3. **Console scaling parameters** create unnecessary complexity
4. **Team identity matters** - DevSecOps vs generic production

### **✅ How We Fixed It:**
1. **Restored DevSecOps file** with standalone, ready-to-use configuration
2. **Pre-configured workers** - no manual scaling required
3. **Clean naming** - consistent container names across environments
4. **Optimized for security** - debug logging, forced queue mode

---

## 📈 **Architecture Evolution**

### **Before (Confusing):**
```bash
❌ 3 files with 90% duplication
❌ Unclear purposes and usage
❌ Maintenance nightmare
```

### **After (Optimized):**
```bash
✅ 3 files with CLEAR purposes:
   - Development: Simple & fast
   - Production: Flexible & scalable  
   - DevSecOps: Security-focused & ready-to-use
✅ No duplication in purpose
✅ Easy maintenance
✅ User-centric design
```

---

## 🎯 **Summary**

### **✅ Final Architecture Benefits:**
- 🎯 **Clear Use Cases**: Each file serves specific user needs
- 🚀 **User Experience**: One-command deployment for each scenario
- 🔧 **Flexible Scaling**: Production file supports dynamic scaling
- 🔒 **Security Focus**: DevSecOps file optimized for security automation
- 🧹 **Clean Purpose**: No confusion about when to use what

### **✅ User Feedback Successfully Integrated:**
- **Restored DevSecOps file** based on valid user concerns
- **Maintained consolidation benefits** while respecting team workflows
- **Balanced complexity reduction** with user experience needs

**🎉 The Docker Compose structure now perfectly serves all user types: Developers, DevOps teams, and Security teams!** 