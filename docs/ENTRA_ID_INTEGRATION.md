# 🔐 Microsoft Entra ID Integration Guide

Hướng dẫn tích hợp n8n với Microsoft Entra ID (Azure Active Directory) thông qua SAML SSO.

## 🎯 Tổng Quan

### ✅ **Tính Năng Hỗ Trợ:**
- **SAML 2.0 SSO** - Single Sign-On với Entra ID
- **Automatic User Provisioning** - Tự động tạo user từ Entra ID  
- **Role Mapping** - Map Azure AD Groups → n8n Roles
- **Group-based Access Control** - Phân quyền theo groups
- **Just-in-Time (JIT) Provisioning** - Tạo user tự động khi login đầu tiên

### 🏗️ **Architecture Flow:**
```
User → Entra ID → SAML Response → n8n → Auto User Creation + Role Assignment
```

## 🚀 Quick Setup

### **Option 1: Automated Script**
```bash
# Run the interactive setup script
./scripts/setup-entra-id.sh
```

### **Option 2: Manual Configuration**
Follow the detailed steps below.

## 📋 Prerequisites

### **Azure AD Side:**
- [ ] Azure AD Premium license (for enterprise apps)
- [ ] Global Administrator hoặc Application Administrator role
- [ ] Domain name với SSL certificate
- [ ] Users/Groups đã được tạo trong Azure AD

### **n8n Side:**
- [ ] n8n production setup đã chạy
- [ ] Domain name pointing to n8n server
- [ ] SSL certificate configured (HTTPS required)
- [ ] User management đã enabled

## 🔧 Azure AD Configuration

### **Step 1: Tạo Enterprise Application**

1. **Login to Azure Portal:** https://portal.azure.com
2. **Navigate:** Azure Active Directory → Enterprise applications
3. **Create:** New application → Create your own application
4. **Name:** "n8n Workflow Automation"
5. **Type:** Integrate any other application you don't find in the gallery

### **Step 2: Configure SAML SSO**

1. **Navigate:** Enterprise application → Single sign-on
2. **Select:** SAML
3. **Basic SAML Configuration:**

```
Entity ID (Identifier): https://your-domain.com/n8n
Reply URL (ACS): https://your-domain.com/rest/sso/saml/acs
Sign on URL: https://your-domain.com
```

4. **User Attributes & Claims:**
```
Required Claims:
- emailaddress: user.mail
- givenname: user.givenname  
- surname: user.surname

Optional Claims (for role mapping):
- groups: user.assignedgroups
```

### **Step 3: Download Metadata**

1. **SAML Certificates section**
2. **Download:** Federation Metadata XML
3. **Copy:** App Federation Metadata Url

Metadata URL format:
```
https://login.microsoftonline.com/{tenant-id}/federationmetadata/2007-06/federationmetadata.xml
```

### **Step 4: Assign Users/Groups**

1. **Navigate:** Enterprise application → Users and groups  
2. **Add:** Users hoặc Groups
3. **Assign roles** (nếu có custom roles)

## ⚙️ n8n Configuration

### **Step 1: Update Environment Variables**

Cập nhật `.env` file:

```bash
# ===========================================
# SAML SSO CONFIGURATION (Entra ID)
# ===========================================

# Enable SAML
N8N_SAML_ENABLED=true

# Entity Configuration
N8N_SAML_ENTITY_ID=https://your-domain.com/n8n
N8N_SAML_ASSERT_URL=https://your-domain.com/rest/sso/saml/acs

# Metadata Configuration (chọn 1 trong 2)
N8N_SAML_METADATA_URL=https://login.microsoftonline.com/{tenant-id}/federationmetadata/2007-06/federationmetadata.xml
# hoặc
# N8N_SAML_METADATA_FILE=/home/node/.n8n/saml-metadata.xml

# User Attribute Mapping
N8N_SAML_EMAIL_ATTRIBUTE=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
N8N_SAML_FIRST_NAME_ATTRIBUTE=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname
N8N_SAML_LAST_NAME_ATTRIBUTE=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname

# Security Settings
N8N_SAML_SIGNED_RESPONSE=true
N8N_SAML_SIGNED_ASSERTION=true
N8N_SAML_LOGIN_ENABLED=true
N8N_SAML_LOGIN_LABEL=Sign in with Microsoft

# Domain Configuration
N8N_HOST=your-domain.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://your-domain.com

# Disable basic auth khi SAML active
N8N_BASIC_AUTH_ACTIVE=false
N8N_USER_MANAGEMENT_DISABLED=false
```

### **Step 2: Configure Role Mapping (Optional)**

Để map Azure AD Groups → n8n Roles:

```bash
# Role Mapping Configuration
N8N_SAML_ROLE_MAPPING_ENABLED=true
N8N_SAML_USER_ROLE_ATTRIBUTE=http://schemas.microsoft.com/ws/2008/06/identity/claims/groups

# Group to Role Mapping
N8N_SAML_ROLE_OWNER_GROUPS=n8n-owners
N8N_SAML_ROLE_ADMIN_GROUPS=n8n-admins,n8n-owners
N8N_SAML_ROLE_MEMBER_GROUPS=n8n-members,n8n-admins,n8n-owners
N8N_SAML_ROLE_GUEST_GROUPS=n8n-guests

# Default role nếu không match group nào
N8N_SAML_DEFAULT_ROLE=member
```

### **Step 3: Azure AD Groups Setup**

Tạo các Security Groups trong Azure AD:

```bash
# Tạo groups trong Azure AD
- n8n-owners    (Owner role)
- n8n-admins    (Admin role)  
- n8n-members   (Member role)
- n8n-guests    (Guest role)
```

### **Step 4: Restart Services**

```bash
# Apply configuration changes
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# Check logs
docker-compose logs -f n8n
```

## 🔐 Advanced Configuration

### **Conditional Access Policies**

Tạo Conditional Access trong Azure AD:

1. **Navigate:** Azure AD → Security → Conditional access
2. **Create:** New policy
3. **Assignments:**
   - Users: n8n users/groups
   - Applications: n8n enterprise app
4. **Conditions:**
   - Locations: Trusted networks only
   - Device platforms: Managed devices
5. **Access controls:**
   - Grant: Require MFA
   - Session: Sign-in frequency

### **Multi-Tenant Support**

Để support multiple tenants:

```bash
# Multiple tenant metadata URLs
N8N_SAML_METADATA_URL=https://login.microsoftonline.com/common/federationmetadata/2007-06/federationmetadata.xml

# Tenant-specific attributes
N8N_SAML_TENANT_ATTRIBUTE=http://schemas.microsoft.com/identity/claims/tenantid
```

### **Custom Claims Configuration**

Azure AD Custom Claims setup:

```json
{
  "ClaimsTransformation": {
    "n8n_role": {
      "TransformationMethod": "ExtractGroups",
      "Parameters": {
        "groupFilterPrefix": "n8n-"
      }
    }
  }
}
```

## 🧪 Testing Integration

### **Step 1: Test SAML Response**

```bash
# Test metadata accessibility
curl -v "https://login.microsoftonline.com/{tenant-id}/federationmetadata/2007-06/federationmetadata.xml"

# Check n8n SAML endpoint
curl -v "https://your-domain.com/rest/sso/saml/metadata"
```

### **Step 2: Test User Login**

1. **Navigate:** https://your-domain.com
2. **Click:** "Sign in with Microsoft"
3. **Verify:** Azure AD login redirect
4. **Check:** User auto-creation trong n8n
5. **Validate:** Correct role assignment

### **Step 3: Monitor Logs**

```bash
# n8n logs
docker-compose logs -f n8n | grep -i saml

# Azure AD Sign-in logs
# Portal → Azure AD → Monitoring → Sign-ins
```

## 🚨 Troubleshooting

### **Common Issues:**

#### **1. SAML Response Invalid**
```bash
# Symptoms: SAML login fails với error message
# Solutions:
- Verify SSL certificate is valid
- Check Entity ID matches exactly
- Validate Reply URL configuration
- Check system clock synchronization
```

#### **2. User Not Created**
```bash
# Symptoms: Login successful nhưng user không được tạo
# Solutions:
- Check email attribute mapping
- Verify user provisioning enabled
- Check n8n logs for errors
- Validate required claims present
```

#### **3. Wrong Role Assignment**
```bash
# Symptoms: User created với wrong role
# Solutions:
- Check group membership in Azure AD
- Verify group claim configuration
- Review role mapping settings
- Check default role setting
```

#### **4. Certificate Validation Errors**
```bash
# Symptoms: Certificate validation failed
# Solutions:
- Update Azure AD certificate in n8n
- Check certificate expiration
- Verify certificate chain
- Validate metadata URL accessibility
```

### **Debug Commands:**

```bash
# Check SAML metadata
curl -s "https://your-domain.com/rest/sso/saml/metadata" | xmllint --format -

# Test SAML assertion
# Use SAML tracer browser extension

# Check n8n SAML config
docker-compose exec n8n env | grep SAML

# Validate SSL certificate
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

## 📊 Monitoring & Auditing

### **Azure AD Monitoring:**

1. **Sign-in Logs:** Monitor successful/failed logins
2. **Audit Logs:** Track configuration changes
3. **Risk Events:** Monitor suspicious activities
4. **Usage Analytics:** Track application usage

### **n8n Monitoring:**

```bash
# Monitor SAML logins
docker-compose logs -f n8n | grep -E "(saml|login|auth)"

# Check user creation events
docker-compose logs -f n8n | grep -E "(user.*created|user.*updated)"

# Monitor role assignments
docker-compose logs -f n8n | grep -E "role.*assigned"
```

## 🔄 Migration Strategy

### **From Basic Auth to SAML:**

1. **Preparation Phase:**
   - Configure SAML alongside basic auth
   - Test với limited user group
   - Train users on new login process

2. **Migration Phase:**
   - Enable SAML login
   - Keep basic auth as fallback
   - Migrate users gradually

3. **Completion Phase:**
   - Disable basic auth
   - Remove old credentials
   - Update documentation

### **Rollback Plan:**

```bash
# Emergency rollback to basic auth
sed -i 's/N8N_SAML_ENABLED=true/N8N_SAML_ENABLED=false/' .env
sed -i 's/N8N_BASIC_AUTH_ACTIVE=false/N8N_BASIC_AUTH_ACTIVE=true/' .env
docker-compose -f docker-compose.prod.yml restart n8n
```

## 📚 References

- [n8n SAML Documentation](https://docs.n8n.io/user-management/saml/)
- [Azure AD SAML Guide](https://docs.microsoft.com/en-us/azure/active-directory/saas-apps/tutorial-list)
- [SAML 2.0 Specification](https://docs.oasis-open.org/security/saml/v2.0/)
- [Microsoft Entra ID Documentation](https://docs.microsoft.com/en-us/azure/active-directory/)

---

## 💡 Best Practices

### **Security:**
✅ Always use HTTPS cho SAML endpoints  
✅ Enable certificate validation  
✅ Use signed SAML assertions  
✅ Implement proper session timeout  
✅ Regular certificate rotation  

### **Operations:**
✅ Monitor Azure AD sign-in logs  
✅ Set up alerting cho SAML failures  
✅ Regular backup n8n configurations  
✅ Document group-to-role mappings  
✅ Test disaster recovery procedures  

**🎯 Result:** Secure, scalable Microsoft Entra ID integration với n8n supporting enterprise authentication requirements! 