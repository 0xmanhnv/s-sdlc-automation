#!/bin/bash

# ===========================================
# n8n User Management Setup Script
# ===========================================
# This script helps you enable user management for your n8n installation

set -e

echo "🔧 n8n User Management Setup"
echo "============================"

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
    local is_password="$4"
    
    if [ "$is_password" = "true" ]; then
        echo -n -e "${BLUE}$prompt${NC}"
        if [ -n "$default" ]; then
            echo -e " ${YELLOW}(press Enter for default: $default)${NC}"
        fi
        echo -n ": "
        read -s input
        echo
    else
        echo -n -e "${BLUE}$prompt${NC}"
        if [ -n "$default" ]; then
            echo -e " ${YELLOW}(press Enter for default: $default)${NC}"
        fi
        echo -n ": "
        read input
    fi
    
    if [ -z "$input" ] && [ -n "$default" ]; then
        input="$default"
    fi
    
    eval $var_name="'$input'"
}

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to generate encryption key
generate_encryption_key() {
    openssl rand -base64 32
}

echo -e "${GREEN}This script will help you configure n8n user management.${NC}"
echo ""

# Check if .env exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}Warning: .env file already exists.${NC}"
    echo -n "Do you want to backup and update it? (y/N): "
    read backup_choice
    
    if [[ $backup_choice =~ ^[Yy]$ ]]; then
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
        echo -e "${GREEN}Backup created: .env.backup.$(date +%Y%m%d_%H%M%S)${NC}"
    else
        echo "Exiting without changes."
        exit 0
    fi
else
    if [ ! -f "env.template" ]; then
        echo -e "${RED}Error: env.template file not found!${NC}"
        echo "Please make sure you're running this script from the n8n project root."
        exit 1
    fi
    cp env.template .env
    echo -e "${GREEN}Created .env file from template.${NC}"
fi

echo ""
echo -e "${BLUE}=== Security Configuration ===${NC}"

# Generate encryption key
encryption_key=$(generate_encryption_key)
echo -e "${GREEN}Generated encryption key (32+ characters)${NC}"

# Prompt for passwords
prompt_input "Enter PostgreSQL password" postgres_password "$(generate_password)"
prompt_input "Enter Redis password" redis_password "$(generate_password)"
prompt_input "Enter n8n owner password" owner_password "" "true"

if [ -z "$owner_password" ]; then
    owner_password=$(generate_password)
    echo -e "${GREEN}Generated owner password: $owner_password${NC}"
fi

echo ""
echo -e "${BLUE}=== Owner Account Configuration ===${NC}"

prompt_input "Enter owner email address" owner_email "admin@yourcompany.com"
prompt_input "Enter your company domain (for webhooks)" company_domain "localhost"

echo ""
echo -e "${BLUE}=== Email Configuration (for user invitations) ===${NC}"

echo "Choose email provider:"
echo "1) Gmail"
echo "2) Outlook"
echo "3) Custom SMTP"
echo "4) Skip email setup"

prompt_input "Select option (1-4)" email_choice "4"

case $email_choice in
    1)
        smtp_host="smtp.gmail.com"
        smtp_port="587"
        prompt_input "Enter Gmail address" smtp_user ""
        prompt_input "Enter Gmail app password" smtp_pass "" "true"
        ;;
    2)
        smtp_host="smtp-mail.outlook.com"
        smtp_port="587"
        prompt_input "Enter Outlook email" smtp_user ""
        prompt_input "Enter Outlook password" smtp_pass "" "true"
        ;;
    3)
        prompt_input "Enter SMTP host" smtp_host ""
        prompt_input "Enter SMTP port" smtp_port "587"
        prompt_input "Enter SMTP username" smtp_user ""
        prompt_input "Enter SMTP password" smtp_pass "" "true"
        ;;
    4)
        echo -e "${YELLOW}Skipping email configuration. You can configure it later in .env file.${NC}"
        smtp_host=""
        ;;
esac

echo ""
echo -e "${BLUE}=== User Registration Settings ===${NC}"

echo "Allow user self-registration?"
echo "1) No - Only invite via email (Recommended for production)"
echo "2) Yes - Allow open registration"

prompt_input "Select option (1-2)" signup_choice "1"

if [ "$signup_choice" = "2" ]; then
    signup_allowed="true"
else
    signup_allowed="false"
fi

echo ""
echo -e "${BLUE}=== Updating Configuration ===${NC}"

# Update .env file
sed -i.bak \
    -e "s/N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$encryption_key/" \
    -e "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$postgres_password/" \
    -e "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$redis_password/" \
    -e "s/N8N_BASIC_AUTH_ACTIVE=.*/N8N_BASIC_AUTH_ACTIVE=false/" \
    -e "s/N8N_USER_MANAGEMENT_DISABLED=.*/N8N_USER_MANAGEMENT_DISABLED=false/" \
    -e "s/N8N_OWNER_EMAIL=.*/N8N_OWNER_EMAIL=$owner_email/" \
    -e "s/N8N_OWNER_PASSWORD=.*/N8N_OWNER_PASSWORD=$owner_password/" \
    -e "s/N8N_SIGNUP_ALLOWED=.*/N8N_SIGNUP_ALLOWED=$signup_allowed/" \
    .env

# Update domain settings
if [ "$company_domain" != "localhost" ]; then
    sed -i.bak \
        -e "s/N8N_HOST=.*/N8N_HOST=$company_domain/" \
        -e "s|WEBHOOK_URL=.*|WEBHOOK_URL=https://$company_domain|" \
        -e "s/N8N_PROTOCOL=.*/N8N_PROTOCOL=https/" \
        .env
fi

# Update email settings if configured
if [ -n "$smtp_host" ]; then
    sed -i.bak \
        -e "s/N8N_SMTP_HOST=.*/N8N_SMTP_HOST=$smtp_host/" \
        -e "s/N8N_SMTP_PORT=.*/N8N_SMTP_PORT=$smtp_port/" \
        -e "s/N8N_SMTP_USER=.*/N8N_SMTP_USER=$smtp_user/" \
        -e "s/N8N_SMTP_PASS=.*/N8N_SMTP_PASS=$smtp_pass/" \
        -e "s/N8N_SMTP_SENDER=.*/N8N_SMTP_SENDER=noreply@$company_domain/" \
        .env
fi

# Clean up backup file
rm -f .env.bak

echo -e "${GREEN}✅ Configuration updated successfully!${NC}"
echo ""

echo -e "${BLUE}=== Next Steps ===${NC}"
echo "1. Review your .env file for any additional customizations"
echo "2. Start your n8n services:"
echo "   ${YELLOW}docker-compose -f docker-compose.prod.yml down${NC}"
echo "   ${YELLOW}docker-compose -f docker-compose.prod.yml up -d${NC}"
echo ""
echo "3. Access n8n at http://$company_domain:5678"
echo "4. Set up your owner account with:"
echo "   Email: $owner_email"
echo "   Password: [as configured]"
echo ""

if [ -n "$smtp_host" ]; then
    echo -e "${GREEN}📧 Email configured - you can invite users via Settings → Users${NC}"
else
    echo -e "${YELLOW}📧 Email not configured - users must be created manually${NC}"
fi

echo ""
echo -e "${BLUE}=== Security Reminders ===${NC}"
echo "🔒 Your encryption key: $encryption_key"
echo "   ${RED}SAVE THIS KEY SAFELY - you cannot recover credentials without it!${NC}"
echo ""
echo "🛡️  For production deployment:"
echo "   - Set up HTTPS with reverse proxy"
echo "   - Configure firewall rules"
echo "   - Set up regular backups"
echo "   - Review the security guide: SECURITY.md"
echo ""

echo -e "${GREEN}Setup completed! 🎉${NC}" 