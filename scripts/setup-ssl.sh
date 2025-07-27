#!/bin/bash

# ===========================================
# n8n SSL Certificate Setup Script
# ===========================================

set -e

echo "🔐 n8n SSL Certificate Setup"
echo "============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt for input
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    
    echo -n -e "${BLUE}$prompt${NC}"
    if [ -n "$default" ]; then
        echo -e " ${YELLOW}(default: $default)${NC}"
    fi
    echo -n ": "
    read input
    
    if [ -z "$input" ] && [ -n "$default" ]; then
        input="$default"
    fi
    
    eval $var_name="'$input'"
}

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command_exists docker; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

if ! command_exists docker-compose; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Check if .env exists
if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        cp env.example .env
        echo -e "${GREEN}✅ Created .env from example${NC}"
    else
        echo -e "${RED}❌ No .env or env.example found!${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}=== SSL Configuration ===${NC}"

prompt_input "Enter your domain name (e.g. n8n.yourcompany.com)" domain ""
prompt_input "Enter your email for SSL certificates" email "admin@${domain}"

# Validate domain
if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${RED}❌ Invalid domain format: $domain${NC}"
    exit 1
fi

# Validate email
if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${RED}❌ Invalid email format: $email${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}=== DNS Configuration ===${NC}"
echo -e "${YELLOW}⚠️  IMPORTANT: Ensure DNS is configured before proceeding${NC}"
echo "Domain: ${domain}"
echo "Email: ${email}"
echo ""
echo "DNS Records needed:"
echo "  A Record: ${domain} → Your server IP"
echo "  CNAME Record: www.${domain} → ${domain} (optional)"
echo ""

read -p "Have you configured DNS records? (y/N): " dns_ready
if [[ ! $dns_ready =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Please configure DNS records first${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}=== Updating Configuration ===${NC}"

# Backup existing .env
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✅ Backup created${NC}"

# Update .env file
sed -i.bak \
    -e "s/N8N_HOST=.*/N8N_HOST=${domain}/" \
    -e "s/N8N_PROTOCOL=.*/N8N_PROTOCOL=https/" \
    -e "s|WEBHOOK_URL=.*|WEBHOOK_URL=https://${domain}|" \
    -e "s/SSL_EMAIL=.*/SSL_EMAIL=${email}/" \
    .env

# Clean up backup file
rm -f .env.bak

echo -e "${GREEN}✅ Configuration updated${NC}"

echo ""
echo -e "${BLUE}=== Creating SSL Directories ===${NC}"

# Create SSL directories
mkdir -p nginx/ssl
mkdir -p nginx/html/.well-known/acme-challenge

# Set proper permissions
chmod 755 nginx/ssl
chmod 755 nginx/html
chmod 755 nginx/html/.well-known
chmod 755 nginx/html/.well-known/acme-challenge

echo -e "${GREEN}✅ SSL directories created${NC}"

echo ""
echo -e "${BLUE}=== Starting Services ===${NC}"

# Start services without SSL profile first
echo "Starting nginx and n8n services..."
docker-compose -f docker-compose.devsecops.yml up -d nginx n8n postgres redis n8n-worker-1 n8n-worker-2

# Wait for nginx to be ready
echo "Waiting for nginx to start..."
sleep 30

# Check if nginx is running
if ! docker-compose -f docker-compose.devsecops.yml ps nginx | grep -q "Up"; then
    echo -e "${RED}❌ Nginx failed to start${NC}"
    docker-compose -f docker-compose.devsecops.yml logs nginx
    exit 1
fi

echo -e "${GREEN}✅ Services started successfully${NC}"

echo ""
echo -e "${BLUE}=== Obtaining SSL Certificate ===${NC}"

# Start certbot with SSL profile
echo "Starting certbot to obtain SSL certificate..."
docker-compose -f docker-compose.devsecops.yml --profile ssl up -d certbot

# Wait for certificate generation
echo "Waiting for certificate generation..."
sleep 60

# Check certificate status
if [ -f "nginx/ssl/certificate.crt" ] && [ -f "nginx/ssl/certificate.key" ]; then
    echo -e "${GREEN}✅ SSL certificate obtained successfully${NC}"
    
    # Restart nginx to use SSL config
    echo "Restarting nginx with SSL configuration..."
    docker-compose -f docker-compose.devsecops.yml restart nginx
    
    sleep 10
    
    # Test HTTPS
    echo "Testing HTTPS connection..."
    if curl -s -o /dev/null -w "%{http_code}" "https://${domain}" | grep -q "200\|302"; then
        echo -e "${GREEN}✅ HTTPS is working correctly${NC}"
    else
        echo -e "${YELLOW}⚠️  HTTPS test failed, but certificate was obtained${NC}"
    fi
else
    echo -e "${RED}❌ SSL certificate generation failed${NC}"
    echo "Checking certbot logs..."
    docker-compose -f docker-compose.devsecops.yml logs certbot
    exit 1
fi

echo ""
echo -e "${BLUE}=== SSL Setup Complete ===${NC}"
echo -e "${GREEN}🎉 SSL certificate setup completed successfully!${NC}"
echo ""
echo -e "${BLUE}Access URLs:${NC}"
echo "  🔐 HTTPS: ${YELLOW}https://${domain}${NC}"
echo "  🌐 HTTP:  ${YELLOW}http://${domain}${NC} (redirects to HTTPS)"
echo ""
echo -e "${BLUE}Certificate Details:${NC}"
echo "  📧 Email: ${email}"
echo "  🔄 Auto-renewal: Every 12 hours"
echo "  📁 Certificate location: nginx/ssl/"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Test your n8n installation at https://${domain}"
echo "2. Configure user management if needed"
echo "3. Set up SAML SSO if required"
echo "4. Monitor certificate renewal logs"
echo ""
echo -e "${YELLOW}For troubleshooting, check logs with:${NC}"
echo "  docker-compose -f docker-compose.devsecops.yml logs certbot"
echo "  docker-compose -f docker-compose.devsecops.yml logs nginx"
echo ""
echo -e "${GREEN}Setup completed! 🎉${NC}" 