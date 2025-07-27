#!/bin/bash

# ===========================================
# N8N Deployment Guide Script
# ===========================================
# Hướng dẫn triển khai từng bước

set -e

echo "🚀 N8N Deployment Guide"
echo "======================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to show step
show_step() {
    local step=$1
    local title=$2
    echo -e "\n${PURPLE}Step ${step}: ${title}${NC}"
    echo "----------------------------------------"
}

# Function to show command
show_command() {
    local cmd=$1
    local desc=$2
    echo -e "${BLUE}Command:${NC} ${cmd}"
    if [ -n "$desc" ]; then
        echo -e "${YELLOW}Description:${NC} ${desc}"
    fi
    echo ""
}

# Function to show environment choice
show_environment_choice() {
    echo -e "\n${GREEN}🎯 Choose Your Environment:${NC}"
    echo "=================================="
    
    echo -e "\n${BLUE}1. Development (Simple)${NC}"
    echo "   - 2 services: PostgreSQL + n8n"
    echo "   - No SSL, direct port access"
    echo "   - Perfect for learning/testing"
    echo "   - Access: http://localhost:5678"
    
    echo -e "\n${BLUE}2. DevSecOps (Security Automation)${NC}"
    echo "   - 7 services: Full stack with 2 workers"
    echo "   - SSL support, container security"
    echo "   - Pre-configured for SAST automation"
    echo "   - Access: https://localhost"
    
    echo -e "\n${BLUE}3. Production (Enterprise)${NC}"
    echo "   - 5 services: Full stack with scaling"
    echo "   - SSL support, container security"
    echo "   - Flexible worker scaling"
    echo "   - Access: https://localhost"
}

# Function to show setup steps
show_setup_steps() {
    show_step "1" "Environment Setup"
    
    echo -e "${YELLOW}📝 Create .env file:${NC}"
    show_command "cp env.template .env" "Copy environment template"
    show_command "nano .env" "Edit with your values"
    
    echo -e "${YELLOW}🔑 Required Variables:${NC}"
    echo "  - N8N_ENCRYPTION_KEY (generate: openssl rand -base64 32)"
    echo "  - POSTGRES_PASSWORD (strong password)"
    echo "  - REDIS_PASSWORD (strong password)"
    echo "  - N8N_OWNER_PASSWORD (admin password)"
    
    echo -e "${YELLOW}🌐 For Production/DevSecOps:${NC}"
    echo "  - N8N_HOST (your domain)"
    echo "  - SSL_EMAIL (for Let's Encrypt)"
    
    show_step "2" "Test Configuration"
    show_command "./scripts/test-docker-compose.sh" "Test all docker-compose files"
    
    show_step "3" "Choose Environment"
    show_environment_choice
}

# Function to show deployment commands
show_deployment_commands() {
    show_step "4" "Deployment Commands"
    
    echo -e "\n${GREEN}🔧 Development:${NC}"
    show_command "docker-compose up -d" "Start development environment"
    show_command "docker-compose logs -f" "View logs"
    show_command "docker-compose down" "Stop environment"
    
    echo -e "\n${GREEN}🔒 DevSecOps:${NC}"
    show_command "docker-compose -f docker-compose.devsecops.yml up -d" "Start DevSecOps environment"
    show_command "docker-compose -f docker-compose.devsecops.yml logs -f" "View logs"
    show_command "docker-compose -f docker-compose.devsecops.yml down" "Stop environment"
    
    echo -e "\n${GREEN}🏭 Production:${NC}"
    show_command "docker-compose -f docker-compose.prod.yml up -d" "Start production environment"
    show_command "docker-compose -f docker-compose.prod.yml up -d --scale n8n-worker=2" "Start with 2 workers"
    show_command "docker-compose -f docker-compose.prod.yml logs -f" "View logs"
    show_command "docker-compose -f docker-compose.prod.yml down" "Stop environment"
}

# Function to show monitoring commands
show_monitoring_commands() {
    show_step "5" "Monitoring & Management"
    
    echo -e "\n${GREEN}📊 Container Status:${NC}"
    show_command "docker ps" "Show running containers"
    show_command "docker-compose ps" "Show compose services"
    
    echo -e "\n${GREEN}📋 Logs:${NC}"
    show_command "docker-compose logs -f [service]" "Follow logs for specific service"
    show_command "docker-compose logs n8n" "View n8n logs"
    show_command "docker-compose logs postgres" "View database logs"
    
    echo -e "\n${GREEN}🔍 Health Checks:${NC}"
    show_command "./scripts/container-security-check.sh" "Check container security"
    show_command "docker exec n8n_app n8n healthcheck" "Check n8n health"
    
    echo -e "\n${GREEN}💾 Backup:${NC}"
    show_command "docker-compose exec postgres pg_dump -U n8n n8n > backup.sql" "Backup database"
    show_command "docker cp n8n_app:/home/node/.n8n ./n8n_backup/" "Backup n8n data"
}

# Function to show troubleshooting
show_troubleshooting() {
    show_step "6" "Troubleshooting"
    
    echo -e "\n${GREEN}🔧 Common Issues:${NC}"
    
    echo -e "\n${YELLOW}Port already in use:${NC}"
    show_command "sudo lsof -i :5678" "Check what's using port 5678"
    show_command "sudo lsof -i :80" "Check what's using port 80"
    show_command "sudo lsof -i :443" "Check what's using port 443"
    
    echo -e "\n${YELLOW}Container won't start:${NC}"
    show_command "docker-compose logs [service]" "Check service logs"
    show_command "docker-compose config" "Validate configuration"
    
    echo -e "\n${YELLOW}SSL issues:${NC}"
    show_command "docker-compose logs certbot" "Check SSL certificate logs"
    show_command "docker-compose logs nginx" "Check nginx logs"
    
    echo -e "\n${YELLOW}Database issues:${NC}"
    show_command "docker-compose exec postgres psql -U n8n -d n8n" "Connect to database"
    show_command "docker-compose logs postgres" "Check database logs"
    
    echo -e "\n${YELLOW}Reset everything:${NC}"
    show_command "docker-compose down -v" "Stop and remove volumes"
    show_command "docker system prune -a" "Clean up Docker (careful!)"
}

# Function to show quick start
show_quick_start() {
    echo -e "\n${GREEN}⚡ Quick Start Guide:${NC}"
    echo "========================"
    
    echo -e "\n${BLUE}For Development:${NC}"
    echo "1. cp env.template .env"
    echo "2. nano .env  # Set passwords"
    echo "3. docker-compose up -d"
    echo "4. Open http://localhost:5678"
    
    echo -e "\n${BLUE}For DevSecOps:${NC}"
    echo "1. cp env.template .env"
    echo "2. nano .env  # Set passwords and domain"
    echo "3. docker-compose -f docker-compose.devsecops.yml up -d"
    echo "4. Open https://localhost"
    
    echo -e "\n${BLUE}For Production:${NC}"
    echo "1. cp env.template .env"
    echo "2. nano .env  # Set all required values"
    echo "3. docker-compose -f docker-compose.prod.yml up -d"
    echo "4. Open https://localhost"
}

# Main function
main() {
    echo -e "${BLUE}Welcome to N8N Deployment Guide!${NC}"
    echo "This script will help you deploy N8N automation platform."
    
    show_setup_steps
    show_deployment_commands
    show_monitoring_commands
    show_troubleshooting
    show_quick_start
    
    echo -e "\n${GREEN}🎉 Deployment Guide Complete!${NC}"
    echo -e "\n${BLUE}Next Steps:${NC}"
    echo "1. Follow the setup steps above"
    echo "2. Choose your environment"
    echo "3. Run the deployment command"
    echo "4. Monitor the deployment"
    echo "5. Access your N8N instance"
    
    echo -e "\n${YELLOW}Need help?${NC}"
    echo "- Check the troubleshooting section"
    echo "- Review the logs: docker-compose logs -f"
    echo "- Run security check: ./scripts/container-security-check.sh"
}

# Run main function
main 