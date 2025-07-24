#!/bin/bash

# ===========================================
# n8n Entra ID/Azure AD SAML Setup Script
# ===========================================

set -e

echo "🔐 n8n Entra ID Integration Setup"
echo "=================================="

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
            echo -e " ${YELLOW}(default: $default)${NC}"
        fi
        echo -n ": "
        read -s input
        echo
    else
        echo -n -e "${BLUE}$prompt${NC}"
        if [ -n "$default" ]; then
            echo -e " ${YELLOW}(default: $default)${NC}"
        fi
        echo -n ": "
        read input
    fi
    
    if [ -z "$input" ] && [ -n "$default" ]; then
        input="$default"
    fi
    
    eval $var_name="'$input'"
}

echo -e "${GREEN}This script will configure n8n SAML integration with Microsoft Entra ID.${NC}"
echo -e "${YELLOW}Prerequisites:${NC}"
echo "1. Entra ID Enterprise Application created"
echo "2. SAML configuration completed in Azure"
echo "3. Users/Groups assigned to the application"
echo "4. SSL certificate configured for your domain"
echo ""

read -p "Have you completed the Azure AD setup? (y/N): " azure_ready
if [[ ! $azure_ready =~ ^[Yy]$ ]]; then
    echo -e "${RED}Please complete the Azure AD setup first following the documentation.${NC}"
    echo "See: docs/ENTRA_ID_INTEGRATION.md for detailed steps"
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    if [ -f "env.template" ]; then
        cp env.template .env
        echo -e "${GREEN}Created .env from template${NC}"
    else
        echo -e "${RED}No .env or env.template found!${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}=== Azure AD Information ===${NC}"

prompt_input "Enter your Azure AD Tenant ID" tenant_id ""
prompt_input "Enter your domain (e.g. company.com)" domain ""
prompt_input "Enter n8n subdomain (e.g. n8n)" subdomain "n8n"

full_domain="${subdomain}.${domain}"

echo ""
echo -e "${BLUE}=== SAML Configuration ===${NC}"

echo "Choose metadata configuration method:"
echo "1) Use Metadata URL (Recommended)"
echo "2) Upload Metadata File"
prompt_input "Select option (1-2)" metadata_choice "1"

if [ "$metadata_choice" = "1" ]; then
    metadata_url="https://login.microsoftonline.com/${tenant_id}/federationmetadata/2007-06/federationmetadata.xml"
    echo -e "${GREEN}Using metadata URL: $metadata_url${NC}"
else
    prompt_input "Enter path to metadata XML file" metadata_file "/home/node/.n8n/saml-metadata.xml"
fi

echo ""
echo -e "${BLUE}=== Role Mapping ===${NC}"

echo "Configure Azure AD Group to n8n Role mapping?"
echo "1) Yes - Configure group mapping"
echo "2) No - All users get default member role"
prompt_input "Select option (1-2)" role_mapping "1"

if [ "$role_mapping" = "1" ]; then
    prompt_input "Owner group name in Azure AD" owner_group "n8n-owners"
    prompt_input "Admin group name in Azure AD" admin_group "n8n-admins"
    prompt_input "Member group name in Azure AD" member_group "n8n-members"
    prompt_input "Guest group name in Azure AD" guest_group "n8n-guests"
    
    echo -e "${GREEN}Role mapping configured:${NC}"
    echo "  Owner: $owner_group"
    echo "  Admin: $admin_group"
    echo "  Member: $member_group"
    echo "  Guest: $guest_group"
fi

echo ""
echo -e "${BLUE}=== SSL Configuration ===${NC}"

echo "SSL Certificate setup:"
echo "1) Let's Encrypt (Certbot)"
echo "2) Custom certificate files"
echo "3) Reverse proxy handles SSL"
prompt_input "Select option (1-3)" ssl_choice "3"

echo ""
echo -e "${BLUE}=== Updating Configuration ===${NC}"

# Backup existing .env
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}Backup created${NC}"

# Update basic SAML settings
sed -i.bak \
    -e "s/N8N_HOST=.*/N8N_HOST=${full_domain}/" \
    -e "s/N8N_PROTOCOL=.*/N8N_PROTOCOL=https/" \
    -e "s|WEBHOOK_URL=.*|WEBHOOK_URL=https://${full_domain}|" \
    -e "s/N8N_BASIC_AUTH_ACTIVE=.*/N8N_BASIC_AUTH_ACTIVE=false/" \
    -e "s/N8N_USER_MANAGEMENT_DISABLED=.*/N8N_USER_MANAGEMENT_DISABLED=false/" \
    .env

# Add or update SAML configuration
if ! grep -q "N8N_SAML_ENABLED" .env; then
    cat >> .env << EOF

# ===========================================
# SAML SSO CONFIGURATION (Entra ID)
# ===========================================
N8N_SAML_ENABLED=true
N8N_SAML_ENTITY_ID=https://${full_domain}/n8n
N8N_SAML_ASSERT_URL=https://${full_domain}/rest/sso/saml/acs

# User Attribute Mapping
N8N_SAML_EMAIL_ATTRIBUTE=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
N8N_SAML_FIRST_NAME_ATTRIBUTE=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname
N8N_SAML_LAST_NAME_ATTRIBUTE=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname

# Security Settings
N8N_SAML_SIGNED_RESPONSE=true
N8N_SAML_SIGNED_ASSERTION=true
N8N_SAML_LOGIN_ENABLED=true
N8N_SAML_LOGIN_LABEL=Sign in with Microsoft
EOF
else
    # Update existing SAML configuration
    sed -i.bak \
        -e "s/N8N_SAML_ENABLED=.*/N8N_SAML_ENABLED=true/" \
        -e "s|N8N_SAML_ENTITY_ID=.*|N8N_SAML_ENTITY_ID=https://${full_domain}/n8n|" \
        -e "s|N8N_SAML_ASSERT_URL=.*|N8N_SAML_ASSERT_URL=https://${full_domain}/rest/sso/saml/acs|" \
        .env
fi

# Configure metadata
if [ "$metadata_choice" = "1" ]; then
    if grep -q "N8N_SAML_METADATA_URL" .env; then
        sed -i.bak "s|N8N_SAML_METADATA_URL=.*|N8N_SAML_METADATA_URL=${metadata_url}|" .env
    else
        echo "N8N_SAML_METADATA_URL=${metadata_url}" >> .env
    fi
    # Remove metadata file setting if it exists
    sed -i.bak '/N8N_SAML_METADATA_FILE/d' .env
else
    if grep -q "N8N_SAML_METADATA_FILE" .env; then
        sed -i.bak "s|N8N_SAML_METADATA_FILE=.*|N8N_SAML_METADATA_FILE=${metadata_file}|" .env
    else
        echo "N8N_SAML_METADATA_FILE=${metadata_file}" >> .env
    fi
    # Remove metadata URL setting if it exists
    sed -i.bak '/N8N_SAML_METADATA_URL/d' .env
fi

# Configure role mapping
if [ "$role_mapping" = "1" ]; then
    # Remove existing role mapping if present
    sed -i.bak '/# Role Mapping Configuration/,/N8N_SAML_DEFAULT_ROLE/d' .env
    
    cat >> .env << EOF

# Role Mapping Configuration
N8N_SAML_ROLE_MAPPING_ENABLED=true
N8N_SAML_USER_ROLE_ATTRIBUTE=http://schemas.microsoft.com/ws/2008/06/identity/claims/groups
N8N_SAML_ROLE_OWNER_GROUPS=${owner_group}
N8N_SAML_ROLE_ADMIN_GROUPS=${admin_group},${owner_group}
N8N_SAML_ROLE_MEMBER_GROUPS=${member_group},${admin_group},${owner_group}
N8N_SAML_ROLE_GUEST_GROUPS=${guest_group}
N8N_SAML_DEFAULT_ROLE=member
EOF
fi

# Clean up backup file
rm -f .env.bak

echo -e "${GREEN}✅ Configuration updated successfully!${NC}"
echo ""

echo -e "${BLUE}=== Next Steps ===${NC}"
echo "1. Verify your .env configuration"
echo "2. Ensure SSL certificates are properly configured"
echo "3. Update DNS records to point ${full_domain} to your server"
echo "4. Restart n8n services:"
echo "   ${YELLOW}docker-compose -f docker-compose.prod.yml down${NC}"
echo "   ${YELLOW}docker-compose -f docker-compose.prod.yml up -d${NC}"
echo ""
echo "5. Test SAML login:"
echo "   Navigate to: ${YELLOW}https://${full_domain}${NC}"
echo "   Click: ${YELLOW}'Sign in with Microsoft'${NC}"
echo ""

echo -e "${BLUE}=== Azure AD Configuration Summary ===${NC}"
echo "Add these URLs to your Azure AD Enterprise Application:"
echo "🔗 Entity ID: ${YELLOW}https://${full_domain}/n8n${NC}"
echo "🔗 Reply URL: ${YELLOW}https://${full_domain}/rest/sso/saml/acs${NC}"
echo "🔗 Sign-on URL: ${YELLOW}https://${full_domain}${NC}"
echo ""

if [ "$role_mapping" = "1" ]; then
    echo -e "${BLUE}=== Role Mapping Configured ===${NC}"
    echo "Ensure these groups exist in Azure AD and are assigned to users:"
    echo "👑 Owner: ${owner_group}"
    echo "⚙️  Admin: ${admin_group}"
    echo "👥 Member: ${member_group}"
    echo "👀 Guest: ${guest_group}"
    echo ""
fi

echo -e "${BLUE}=== Required Azure AD Configuration ===${NC}"
echo "1. Create Security Groups in Azure AD:"
if [ "$role_mapping" = "1" ]; then
    echo "   - ${owner_group}"
    echo "   - ${admin_group}"
    echo "   - ${member_group}"
    echo "   - ${guest_group}"
fi
echo ""
echo "2. Configure User Attributes & Claims in Azure AD:"
echo "   - emailaddress: user.mail"
echo "   - givenname: user.givenname"
echo "   - surname: user.surname"
if [ "$role_mapping" = "1" ]; then
    echo "   - groups: user.assignedgroups"
fi
echo ""

echo -e "${BLUE}=== Troubleshooting ===${NC}"
echo "If SAML login fails:"
echo "1. Check n8n logs: ${YELLOW}docker-compose logs -f n8n${NC}"
echo "2. Verify SSL certificate is valid"
echo "3. Check Azure AD enterprise app sign-in logs"
echo "4. Validate metadata URL accessibility:"
echo "   ${YELLOW}curl -v \"${metadata_url}\"${NC}"
echo "5. Test n8n SAML metadata:"
echo "   ${YELLOW}curl -v \"https://${full_domain}/rest/sso/saml/metadata\"${NC}"
echo ""

echo -e "${GREEN}Setup completed! 🎉${NC}"
echo -e "${YELLOW}Remember to test the integration before deploying to production.${NC}"
echo ""
echo -e "${BLUE}For detailed documentation, see: docs/ENTRA_ID_INTEGRATION.md${NC}" 