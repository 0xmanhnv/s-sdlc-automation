# 👥 N8N User Management Guide

n8n hỗ trợ đầy đủ tính năng quản lý người dùng cho môi trường doanh nghiệp với nhiều người dùng.

## 🎯 Tính Năng User Management

### ✅ **Các Tính Năng Chính:**

1. **Multi-User Support** - Hỗ trợ nhiều người dùng
2. **Role-Based Access Control (RBAC)** - Phân quyền theo vai trò
3. **Workflow Sharing** - Chia sẻ workflow giữa các user
4. **Credential Sharing** - Chia sẻ credentials có kiểm soát
5. **User Registration** - Đăng ký người dùng mới
6. **Password Management** - Quản lý mật khẩu
7. **LDAP Integration** - Tích hợp với LDAP
8. **SAML SSO** - Single Sign-On với SAML
9. **Project Management** - Quản lý dự án và teams

## 🚀 Cấu Hình User Management

### 1. **Kích Hoạt User Management**

Cập nhật file `.env` của bạn:

```bash
# Tắt Basic Auth (chỉ dành cho development)
N8N_BASIC_AUTH_ACTIVE=false

# Kích hoạt User Management
N8N_USER_MANAGEMENT_DISABLED=false

# Cấu hình Owner account (user đầu tiên)
N8N_OWNER_EMAIL=admin@yourcompany.com
N8N_OWNER_PASSWORD=your-secure-password

# Cấu hình email (để invite users)
N8N_EMAIL_MODE=smtp
N8N_SMTP_HOST=smtp.gmail.com
N8N_SMTP_PORT=587
N8N_SMTP_USER=your-email@gmail.com
N8N_SMTP_PASS=your-app-password
N8N_SMTP_SENDER=noreply@yourcompany.com

# Cấu hình domain công khai
N8N_HOST=your-domain.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://your-domain.com
```

### 2. **Khởi Tạo Owner Account**

Khi lần đầu truy cập n8n sau khi bật user management:

```bash
# Khởi động lại n8n với cấu hình mới
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# Truy cập http://localhost:5678 để setup owner account
```

### 3. **Cấu Hình Nâng Cao**

```bash
# Cấu hình registration
N8N_SIGNUP_ALLOWED=true  # Cho phép đăng ký tự do
# hoặc
N8N_SIGNUP_ALLOWED=false # Chỉ invite qua email

# Cấu hình mật khẩu
N8N_USER_PASSWORD_MIN_LENGTH=8
N8N_USER_PASSWORD_COMPLEXITY=true

# Cấu hình session
N8N_USER_SESSION_TIMEOUT=86400  # 24 giờ

# Cấu hình invitation
N8N_USER_INVITATION_EXPIRY_TIME=7  # 7 ngày
```

## 👤 Các Loại User và Roles

### **User Types:**

1. **Owner** 👑
   - Quyền cao nhất trong hệ thống
   - Quản lý toàn bộ users và settings
   - Access tất cả workflows và credentials

2. **Admin** ⚙️
   - Quản lý users (trừ Owner)
   - Access tất cả workflows
   - Cấu hình system settings

3. **Member** 👥
   - Tạo và quản lý workflows riêng
   - Access workflows được share
   - Sử dụng credentials được share

4. **Guest** 👀
   - Chỉ xem workflows được share
   - Không thể tạo hoặc chỉnh sửa

### **Permissions Matrix:**

| Action | Owner | Admin | Member | Guest |
|--------|-------|-------|--------|-------|
| Manage Users | ✅ | ✅ | ❌ | ❌ |
| System Settings | ✅ | ✅ | ❌ | ❌ |
| Create Workflows | ✅ | ✅ | ✅ | ❌ |
| Edit Own Workflows | ✅ | ✅ | ✅ | ❌ |
| View Shared Workflows | ✅ | ✅ | ✅ | ✅ |
| Manage Credentials | ✅ | ✅ | Own Only | ❌ |
| Execute Workflows | ✅ | ✅ | ✅ | Shared Only |

## 🏢 Project Management (Enterprise)

### **Tạo Projects:**

```bash
# Cấu hình projects
N8N_PROJECTS_ENABLED=true
N8N_PROJECT_DEFAULT_NAME="Default Project"
```

Projects cho phép:
- Tổ chức workflows theo dự án
- Phân quyền theo team
- Isolated environments
- Shared resources trong team

## 🔐 LDAP Integration

### **Cấu Hình LDAP:**

```bash
# LDAP Settings
N8N_LDAP_ENABLED=true
N8N_LDAP_SERVER=ldap://your-ldap-server.com
N8N_LDAP_PORT=389
N8N_LDAP_BIND_DN=cn=admin,dc=company,dc=com
N8N_LDAP_BIND_CREDENTIALS=admin-password
N8N_LDAP_BASE_DN=dc=company,dc=com
N8N_LDAP_LOGIN_ID_ATTRIBUTE=uid
N8N_LDAP_EMAIL_ATTRIBUTE=mail
N8N_LDAP_FIRST_NAME_ATTRIBUTE=givenName
N8N_LDAP_LAST_NAME_ATTRIBUTE=sn
```

### **LDAP User Sync:**

```bash
# Tự động sync users từ LDAP
N8N_LDAP_SYNC_ENABLED=true
N8N_LDAP_SYNC_INTERVAL=3600  # Sync mỗi giờ
```

## 🔑 SAML SSO Integration

### **Cấu Hình SAML:**

```bash
# SAML Settings
N8N_SAML_ENABLED=true
N8N_SAML_METADATA_URL=https://your-idp.com/metadata
N8N_SAML_ENTITY_ID=https://your-domain.com/n8n
N8N_SAML_ASSERT_URL=https://your-domain.com/rest/sso/saml/acs
N8N_SAML_EMAIL_ATTRIBUTE=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
N8N_SAML_FIRST_NAME_ATTRIBUTE=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname
N8N_SAML_LAST_NAME_ATTRIBUTE=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname
```

## 📧 Email Configuration

### **SMTP Setup cho User Invitations:**

```bash
# Gmail SMTP
N8N_EMAIL_MODE=smtp
N8N_SMTP_HOST=smtp.gmail.com
N8N_SMTP_PORT=587
N8N_SMTP_USER=your-email@gmail.com
N8N_SMTP_PASS=your-app-password
N8N_SMTP_SENDER=noreply@yourcompany.com
N8N_SMTP_SSL=false
N8N_SMTP_TLS=true

# Outlook SMTP
N8N_SMTP_HOST=smtp-mail.outlook.com
N8N_SMTP_PORT=587

# Custom SMTP
N8N_SMTP_HOST=mail.yourcompany.com
N8N_SMTP_PORT=587
```

## 🛠️ Quản Lý Users

### **Thông Qua Web UI:**

1. **Truy cập Settings:** `http://localhost:5678/settings/users`
2. **Invite User:** Click "Invite User" → Nhập email
3. **Manage Roles:** Chọn user → Change role
4. **Remove User:** Select user → Delete

### **Thông Qua API:**

```bash
# Lấy danh sách users
curl -X GET http://localhost:5678/rest/users \
  -H "Authorization: Bearer your-api-token"

# Invite user mới
curl -X POST http://localhost:5678/rest/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-token" \
  -d '{"email": "newuser@company.com", "role": "member"}'

# Cập nhật role
curl -X PATCH http://localhost:5678/rest/users/user-id \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-token" \
  -d '{"role": "admin"}'
```

## 🔄 Migration từ Basic Auth

### **Bước 1: Backup Data**
```bash
# Backup trước khi migration
docker-compose exec postgres pg_dump -U n8n n8n > backup_before_migration.sql
```

### **Bước 2: Cấu Hình Environment**
Cập nhật `.env` file như hướng dẫn trên.

### **Bước 3: Restart Services**
```bash
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

### **Bước 4: Setup Owner Account**
- Truy cập web UI
- Tạo owner account
- Invite other users

## 🚨 Best Practices

### **Security:**
- ✅ Sử dụng strong passwords
- ✅ Enable 2FA nếu có
- ✅ Regular user access review
- ✅ Principle of least privilege
- ✅ Monitor user activities

### **Organization:**
- ✅ Sử dụng Projects để tổ chức
- ✅ Consistent naming conventions
- ✅ Regular cleanup inactive users
- ✅ Document user roles và responsibilities

### **Monitoring:**
```bash
# Monitor user activities
docker-compose logs -f n8n | grep "user"

# Check active sessions
# Thông qua Web UI: Settings → Sessions
```

## 🆘 Troubleshooting

### **Common Issues:**

1. **Owner account không tạo được:**
   ```bash
   # Xóa data và restart
   docker-compose down -v
   docker-compose up -d
   ```

2. **Email invitation không gửi được:**
   - Kiểm tra SMTP settings
   - Test với telnet: `telnet smtp.gmail.com 587`
   - Kiểm tra firewall rules

3. **LDAP connection failed:**
   - Verify LDAP server accessibility
   - Check bind credentials
   - Test LDAP query manually

4. **Users không thể access workflows:**
   - Check workflow sharing settings
   - Verify user roles
   - Review project permissions

## 📚 Resources

- [n8n User Management Docs](https://docs.n8n.io/user-management/)
- [RBAC Documentation](https://docs.n8n.io/user-management/rbac/)
- [LDAP Setup Guide](https://docs.n8n.io/user-management/ldap/)
- [SAML Configuration](https://docs.n8n.io/user-management/saml/)

---

**💡 Tip:** Bắt đầu với basic user management, sau đó mở rộng sang LDAP/SAML khi cần thiết. 