#!/bin/bash

# ===========================================
# n8n Redis Queue Configuration Script
# ===========================================
# Optimizes Redis queue settings for DevSecOps workloads
# Supports: Light, Medium, Heavy workload profiles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   n8n Redis Queue Configuration${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Function to get user input with default
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " value
        if [ -z "$value" ]; then
            value="$default"
        fi
    else
        read -p "$prompt: " value
        while [ -z "$value" ]; do
            echo -e "${RED}This field is required!${NC}"
            read -p "$prompt: " value
        done
    fi
    
    eval "$var_name='$value'"
}

echo -e "${YELLOW}Select your DevSecOps workload profile:${NC}"
echo "1. 🚀 Light    - Small team, basic SAST integration (< 50 workflows/day)"
echo "2. ⚡ Medium   - Multi-team, moderate SAST load (50-200 workflows/day)" 
echo "3. 🔥 Heavy    - Enterprise, high-load security automation (200+ workflows/day)"
echo ""

prompt_input "Choose workload profile (1-3)" profile "2"

# Configure based on profile
case "$profile" in
    "1")
        echo -e "${GREEN}Configuring for Light workload...${NC}"
        redis_memory="256mb"
        queue_workers="1"
        queue_concurrency="5"
        redis_max_connections="100"
        ;;
    "2")
        echo -e "${GREEN}Configuring for Medium workload...${NC}"
        redis_memory="512mb"
        queue_workers="2"
        queue_concurrency="10"
        redis_max_connections="200"
        ;;
    "3")
        echo -e "${GREEN}Configuring for Heavy workload...${NC}"
        redis_memory="1024mb"
        queue_workers="3"
        queue_concurrency="20"
        redis_max_connections="500"
        ;;
    *)
        echo -e "${RED}Invalid selection. Using Medium profile.${NC}"
        redis_memory="512mb"
        queue_workers="2"
        queue_concurrency="10"
        redis_max_connections="200"
        ;;
esac

echo ""
echo -e "${BLUE}=== Queue Configuration ===${NC}"
echo "Redis Memory: $redis_memory"
echo "Queue Workers: $queue_workers"
echo "Queue Concurrency: $queue_concurrency"
echo "Max Connections: $redis_max_connections"
echo ""

# Backup existing .env
if [ -f .env ]; then
    cp .env .env.backup.queue.$(date +%Y%m%d_%H%M%S)
    echo -e "${GREEN}✅ Backed up existing .env file${NC}"
fi

# Update .env file with queue settings
echo -e "${BLUE}=== Updating Environment Configuration ===${NC}"

# Enable queue mode
sed -i 's/QUEUE_MODE=.*/QUEUE_MODE=true/' .env 2>/dev/null || echo "QUEUE_MODE=true" >> .env
sed -i 's/EXECUTIONS_MODE=.*/EXECUTIONS_MODE=queue/' .env 2>/dev/null || echo "EXECUTIONS_MODE=queue" >> .env

# Add queue-specific configurations
if ! grep -q "QUEUE_WORKER_TIMEOUT" .env; then
    echo "" >> .env
    echo "# ============================================" >> .env
    echo "# REDIS QUEUE OPTIMIZATION" >> .env
    echo "# ============================================" >> .env
    echo "QUEUE_WORKER_TIMEOUT=60" >> .env
    echo "N8N_QUEUE_RECOVERY_INTERVAL=60" >> .env
    echo "QUEUE_BULL_MAX_STALLED_COUNT=3" >> .env
    echo "QUEUE_BULL_MAX_RETRIES=3" >> .env
fi

# Add workload-specific settings
if ! grep -q "REDIS_MAX_MEMORY" .env; then
    echo "" >> .env
    echo "# Workload-specific Redis settings" >> .env
    echo "REDIS_MAX_MEMORY=${redis_memory}" >> .env
    echo "REDIS_MAX_CONNECTIONS=${redis_max_connections}" >> .env
    echo "QUEUE_CONCURRENCY=${queue_concurrency}" >> .env
    echo "RECOMMENDED_WORKERS=${queue_workers}" >> .env
fi

echo -e "${GREEN}✅ Queue configuration updated in .env${NC}"

# Create Redis configuration file
echo -e "${BLUE}=== Creating Redis Configuration ===${NC}"

cat > redis.conf << EOF
# ===========================================
# Redis Configuration for n8n DevSecOps
# ===========================================
# Optimized for queue processing and SAST workflows

# Memory Management
maxmemory ${redis_memory}
maxmemory-policy allkeys-lru

# Network & Security
requirepass \${REDIS_PASSWORD}
maxclients ${redis_max_connections}
tcp-keepalive 300

# Persistence for queue reliability
appendonly yes
appendfsync everysec
save 900 1
save 300 10
save 60 10000

# Performance Tuning
tcp-backlog 511
timeout 0
databases 16

# Logging
loglevel notice
syslog-enabled yes
syslog-ident redis-n8n

# Queue-specific optimizations
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
EOF

echo -e "${GREEN}✅ Created optimized redis.conf${NC}"

# Update docker-compose files to use custom Redis config
echo -e "${BLUE}=== Updating Docker Compose Configuration ===${NC}"

if [ -f docker-compose.devsecops.yml ]; then
    # Update DevSecOps compose file
    if ! grep -q "redis.conf" docker-compose.devsecops.yml; then
        sed -i '/volumes:/,/redis_data:\/data/ {
            /redis_data:\/data/a\
      - ./redis.conf:/usr/local/etc/redis/redis.conf:ro
        }' docker-compose.devsecops.yml
        
        # Update command to use config file
        sed -i 's/command: redis-server --requirepass.*/command: redis-server \/usr\/local\/etc\/redis\/redis.conf/' docker-compose.devsecops.yml
    fi
    echo -e "${GREEN}✅ Updated docker-compose.devsecops.yml${NC}"
fi

if [ -f docker-compose.prod.yml ]; then
    # Update production compose file
    if ! grep -q "redis.conf" docker-compose.prod.yml; then
        sed -i '/volumes:/,/redis_data:\/data/ {
            /redis_data:\/data/a\
      - ./redis.conf:/usr/local/etc/redis/redis.conf:ro
        }' docker-compose.prod.yml
        
        # Update command to use config file
        sed -i 's/command: redis-server --requirepass.*/command: redis-server \/usr\/local\/etc\/redis\/redis.conf/' docker-compose.prod.yml
    fi
    echo -e "${GREEN}✅ Updated docker-compose.prod.yml${NC}"
fi

echo ""
echo -e "${BLUE}=== Configuration Complete ===${NC}"
echo -e "${GREEN}✅ Queue mode enabled${NC}"
echo -e "${GREEN}✅ Redis optimized for ${profile} workload${NC}"
echo -e "${GREEN}✅ Configuration files updated${NC}"
echo ""

echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Restart your n8n stack:"
if [ -f docker-compose.devsecops.yml ]; then
    echo "   ${BLUE}docker-compose -f docker-compose.devsecops.yml down${NC}"
    echo "   ${BLUE}docker-compose -f docker-compose.devsecops.yml up -d${NC}"
else
    echo "   ${BLUE}docker-compose -f docker-compose.prod.yml down${NC}"
    echo "   ${BLUE}docker-compose -f docker-compose.prod.yml up -d${NC}"
fi
echo ""
echo "2. Monitor queue performance:"
echo "   ${BLUE}docker-compose logs -f redis${NC}"
echo "   ${BLUE}docker-compose logs -f n8n${NC}"
echo ""
echo "3. Scale workers if needed (DevSecOps only):"
echo "   ${BLUE}docker-compose -f docker-compose.devsecops.yml up -d --scale n8n-worker-1=${queue_workers}${NC}"
echo ""

echo -e "${YELLOW}💡 Performance Tips:${NC}"
echo "• Monitor Redis memory usage: ${BLUE}docker exec -it n8n_redis redis-cli info memory${NC}"
echo "• Check queue status in n8n UI: Settings → Log Streaming"  
echo "• For heavy loads, consider adding more worker instances"
echo ""

echo -e "${GREEN}🎉 Redis Queue configuration completed successfully!${NC}" 