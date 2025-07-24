#!/bin/bash

# ===========================================
# n8n Nginx + SSL Setup Script
# ===========================================

set -e

echo "🌐 n8n Nginx & SSL Setup"
echo "========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo -e "${GREEN}This script will configure nginx reverse proxy with SSL for n8n.${NC}"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${RED}No .env file found! Please run user management setup first.${NC}"
    echo "Run: ./scripts/enable-user-management.sh"
    exit 1
fi

echo -e "${BLUE}=== Domain Configuration ===${NC}"

prompt_input "Enter your domain name (e.g. n8n.company.com)" domain_name ""
prompt_input "Enter your email for SSL certificate" ssl_email "admin@${domain_name}"

if [ -z "$domain_name" ]; then
    echo -e "${RED}Domain name is required!${NC}"
    exit 1
fi

if [ -z "$ssl_email" ]; then
    ssl_email="admin@${domain_name}"
fi

echo ""
echo -e "${BLUE}=== Environment Selection ===${NC}"

echo "Choose deployment environment:"
echo "1) Production with SSL (Recommended)"
echo "2) Development without SSL"
prompt_input "Select option (1-2)" env_choice "1"

echo ""
echo -e "${BLUE}=== SSL Certificate Method ===${NC}"

if [ "$env_choice" = "1" ]; then
    echo "Choose SSL certificate method:"
    echo "1) Let's Encrypt (Automatic - Recommended)"
    echo "2) Custom certificates (Upload your own)"
    prompt_input "Select option (1-2)" ssl_method "1"
fi

echo ""
echo -e "${BLUE}=== Updating Configuration ===${NC}"

# Backup existing .env
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}Backup created${NC}"

# Update environment variables
sed -i.bak \
    -e "s/N8N_HOST=.*/N8N_HOST=${domain_name}/" \
    -e "s|WEBHOOK_URL=.*|WEBHOOK_URL=https://${domain_name}|" \
    .env

# Add SSL email to environment
if ! grep -q "SSL_EMAIL" .env; then
    echo "SSL_EMAIL=${ssl_email}" >> .env
else
    sed -i.bak "s/SSL_EMAIL=.*/SSL_EMAIL=${ssl_email}/" .env
fi

# Set protocol based on environment
if [ "$env_choice" = "1" ]; then
    sed -i.bak "s/N8N_PROTOCOL=.*/N8N_PROTOCOL=https/" .env
    echo -e "${GREEN}Configured for HTTPS production environment${NC}"
else
    sed -i.bak "s/N8N_PROTOCOL=.*/N8N_PROTOCOL=http/" .env
    echo -e "${GREEN}Configured for HTTP development environment${NC}"
fi

# Clean up backup file
rm -f .env.bak

echo ""
echo -e "${BLUE}=== Preparing Nginx Configuration ===${NC}"

# Create nginx directory if it doesn't exist
mkdir -p nginx/html

# Choose nginx configuration based on environment
if [ "$env_choice" = "1" ]; then
    nginx_config="nginx/nginx.conf"
    compose_file="docker-compose.prod.yml"
    echo -e "${GREEN}Using production nginx configuration with SSL${NC}"
else
    # Copy dev config to main config location for development
    cp nginx/nginx-dev.conf nginx/nginx.conf.dev
    nginx_config="nginx/nginx.conf.dev"
    compose_file="docker-compose.dev.yml"
    
    # Note: Dev environment doesn't include nginx by default
    echo -e "${GREEN}Using development nginx configuration (HTTP only)${NC}"
    echo -e "${YELLOW}Note: Development uses direct n8n access. For nginx testing, use production mode.${NC}"
fi

echo ""
echo -e "${BLUE}=== DNS Configuration Check ===${NC}"

echo "Before starting, ensure your DNS is configured:"
echo "🔗 ${domain_name} → Your server IP address"
echo ""

# Check if domain resolves to current server (optional)
server_ip=$(curl -s https://httpbin.org/ip | grep -o '"origin":"[^"]*' | cut -d'"' -f4)
domain_ip=$(dig +short $domain_name | tail -n1)

if [ -n "$domain_ip" ] && [ "$domain_ip" = "$server_ip" ]; then
    echo -e "${GREEN}✅ DNS configuration looks correct${NC}"
    echo "   $domain_name → $domain_ip"
else
    echo -e "${YELLOW}⚠️  DNS may not be configured correctly${NC}"
    echo "   Domain resolves to: ${domain_ip:-'Not found'}"
    echo "   Server IP appears to be: ${server_ip:-'Unknown'}"
    echo ""
    read -p "Continue anyway? (y/N): " continue_choice
    if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
        echo "Please configure DNS first, then run this script again."
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}=== Starting Services ===${NC}"

echo "Starting n8n with nginx reverse proxy..."

if [ "$env_choice" = "1" ]; then
    # Production with SSL
    docker-compose -f docker-compose.prod.yml down --remove-orphans
    docker-compose -f docker-compose.prod.yml up -d
    
    echo ""
    echo -e "${GREEN}✅ Services started successfully!${NC}"
    echo ""
    echo -e "${BLUE}=== SSL Certificate Status ===${NC}"
    echo "Checking SSL certificate setup..."
    
    # Wait for certificate generation
    echo "Waiting for SSL certificate generation (this may take a few minutes)..."
    sleep 30
    
    # Check certificate status
    if docker-compose -f docker-compose.prod.yml logs certbot | grep -q "Successfully received certificate"; then
        echo -e "${GREEN}✅ SSL certificate obtained successfully!${NC}"
    else
        echo -e "${YELLOW}⏳ SSL certificate generation in progress...${NC}"
        echo "Check status with: docker-compose -f docker-compose.prod.yml logs certbot"
    fi
    
else
    # Development without SSL
    echo -e "${YELLOW}Note: For development, use docker-compose.dev.yml directly${NC}"
    echo -e "${YELLOW}Development environment doesn't typically need nginx reverse proxy${NC}"
    docker-compose -f docker-compose.dev.yml down --remove-orphans
    docker-compose -f docker-compose.dev.yml up -d
    
    echo -e "${GREEN}✅ Development services started successfully!${NC}"
fi

echo ""
echo -e "${BLUE}=== Access Information ===${NC}"

if [ "$env_choice" = "1" ]; then
    echo "🌐 n8n URL: ${YELLOW}https://${domain_name}${NC}"
    echo "🔒 SSL: Enabled with Let's Encrypt"
else
    echo "🌐 n8n URL: ${YELLOW}http://${domain_name}${NC}"
    echo "🔓 SSL: Disabled (Development mode)"
fi

echo ""
echo -e "${BLUE}=== Service Status ===${NC}"

if [ "$env_choice" = "1" ]; then
    docker-compose -f docker-compose.prod.yml ps
else
    docker-compose -f docker-compose.dev.yml ps
fi

echo ""
echo -e "${BLUE}=== Next Steps ===${NC}"

if [ "$env_choice" = "1" ]; then
    echo "1. Wait for SSL certificate generation to complete"
    echo "2. Visit https://${domain_name} to access n8n"
    echo "3. Complete user setup or SAML configuration"
    echo ""
    echo "📊 Monitor logs:"
    echo "   ${YELLOW}docker-compose -f docker-compose.prod.yml logs -f${NC}"
    echo ""
    echo "🔍 Check SSL certificate:"
    echo "   ${YELLOW}docker-compose -f docker-compose.prod.yml logs certbot${NC}"
else
    echo "1. Visit http://${domain_name} to access n8n"
    echo "2. Complete user setup"
    echo ""
    echo "📊 Monitor logs:"
    echo "   ${YELLOW}docker-compose -f docker-compose.dev.yml logs -f${NC}"
fi

echo ""
echo -e "${BLUE}=== Troubleshooting ===${NC}"
echo "If you encounter issues:"
echo "1. Check all services are running: docker-compose ps"
echo "2. View nginx logs: docker-compose logs nginx"
echo "3. Verify DNS resolution: dig ${domain_name}"
echo "4. Test nginx config: docker-compose exec nginx nginx -t"

if [ "$env_choice" = "1" ]; then
    echo "5. Check SSL certificate: openssl s_client -connect ${domain_name}:443"
fi

echo ""
echo -e "${GREEN}Setup completed! 🎉${NC}"

if [ "$env_choice" = "1" ]; then
    echo -e "${YELLOW}Note: It may take a few minutes for SSL certificates to be issued.${NC}"
fi 