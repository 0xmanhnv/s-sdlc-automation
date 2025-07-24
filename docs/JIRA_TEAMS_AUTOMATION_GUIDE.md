# 🎫 Jira Cloud + Teams Automation Guide

Complete setup guide for automating Jira Cloud notifications to Microsoft Teams using n8n.

## 🎯 **Use Cases Covered:**

1. **🚨 Critical Issue Alerts** - Instant Teams notifications for critical issues
2. **📋 Status Change Updates** - Track issue progress in Teams channels  
3. **👤 Assignment Notifications** - Direct messages when issues are assigned
4. **📊 Daily Summary Reports** - Automated project updates
5. **🔄 Custom Workflows** - Flexible automation rules

## 🏗️ **Architecture Flow:**

```
Jira Cloud → Webhook → n8n Processing → Teams Notification

┌─────────────┐   webhook   ┌─────────────┐   filter   ┌─────────────┐
│ Jira Event  │ ─────────→  │   n8n       │ ────────→  │   Teams     │
│ (Issue      │             │ • Filter    │            │ • Channel   │
│  Updated)   │             │ • Format    │            │ • DM        │
└─────────────┘             │ • Route     │            │ • Card      │
                            └─────────────┘            └─────────────┘
```

## 📋 **Prerequisites:**

### **Jira Cloud:**
- [ ] Admin access to Jira Cloud instance
- [ ] API token generated
- [ ] Project access permissions

### **Microsoft Teams:**
- [ ] Teams admin permissions
- [ ] Incoming webhook connectors enabled
- [ ] Target channels identified

### **n8n:**
- [ ] n8n instance running (use `docker-compose.dev.yml` for development or `docker-compose.prod.yml` for production)
- [ ] Web interface accessible
- [ ] Webhook URLs available

---

## 🚀 **Step-by-Step Implementation:**

### **Phase 1: Setup Teams Webhooks**

#### **1.1 Create Teams Incoming Webhooks:**

**For Critical Alerts Channel:**
```bash
1. Go to Teams → Your Channel → ... → Connectors
2. Find "Incoming Webhook" → Configure
3. Name: "Jira Critical Alerts"
4. Upload icon (optional)
5. Copy webhook URL → Save as TEAMS_WEBHOOK_CRITICAL
```

**For General Updates Channel:**
```bash
1. Repeat for updates channel
2. Name: "Jira Updates" 
3. Copy webhook URL → Save as TEAMS_WEBHOOK_UPDATES
```

#### **1.2 Test Teams Webhooks:**
```bash
# Test critical webhook
curl -X POST YOUR_TEAMS_WEBHOOK_CRITICAL \
  -H "Content-Type: application/json" \
  -d '{"text": "🧪 Test message from n8n setup"}'
```

### **Phase 2: Configure Jira Cloud**

#### **2.1 Generate Jira API Token:**
```bash
1. Go to: https://id.atlassian.com/manage-profile/security/api-tokens
2. Create API token
3. Copy token → Save as JIRA_API_TOKEN
4. Note your email → Save as JIRA_EMAIL
```

#### **2.2 Get Jira Instance Details:**
```bash
# Your Jira URL format:
JIRA_INSTANCE_URL=https://yourcompany.atlassian.net
PROJECT_KEY=PROJ  # Your project key
```

### **Phase 3: Setup n8n Workflows**

#### **3.1 Import Base Workflow:**
```bash
1. Open n8n web interface
2. Click "Import from URL" or "Import from File"  
3. Import: workflows/jira-teams-automation.json
4. Save as "Jira → Teams Notifications"
```

#### **3.2 Configure Webhook Node:**
```bash
1. Open "Jira Webhook" node
2. Copy the webhook URL (e.g., https://your-n8n.com/webhook/jira-webhook)
3. Set HTTP Method: POST
4. Enable "Respond to Webhook" 
5. Save
```

#### **3.3 Configure Teams Nodes:**
```bash
# Critical Alert Node:
1. Open "Teams Critical Alert" node
2. Set URL: YOUR_TEAMS_WEBHOOK_CRITICAL
3. Method: POST
4. Test with sample data

# Status Update Node:  
1. Open "Teams Status Update" node
2. Set URL: YOUR_TEAMS_WEBHOOK_UPDATES
3. Method: POST
4. Test with sample data
```

#### **3.4 Test n8n Workflow:**
```bash
1. Activate the workflow
2. Send test webhook to n8n:

curl -X POST https://your-n8n.com/webhook/jira-webhook \
  -H "Content-Type: application/json" \
  -d '{
    "webhookEvent": "jira:issue_created",
    "issue": {
      "key": "TEST-123",
      "fields": {
        "summary": "Test issue for automation",
        "priority": {"name": "Critical"},
        "status": {"name": "Open"},
        "assignee": {"displayName": "John Doe"},
        "reporter": {"displayName": "Jane Smith"}
      }
    }
  }'
```

### **Phase 4: Configure Jira Webhooks**

#### **4.1 Create Jira Webhooks:**
```bash
1. Go to Jira → Settings (⚙️) → System → Webhooks
2. Click "Create a WebHook"
3. Configure:
   - Name: "n8n Teams Integration"
   - Status: Enabled
   - URL: https://your-n8n.com/webhook/jira-webhook
   - Events: 
     ✓ Issue Created
     ✓ Issue Updated  
     ✓ Issue Deleted
     ✓ Issue Commented
4. Create
```

#### **4.2 Test End-to-End:**
```bash
1. Create a test issue in Jira with "Critical" priority
2. Check Teams channel for notification
3. Update issue status
4. Verify Teams update notification
```

---

## 🔧 **Advanced Configurations:**

### **🎯 Filtering Rules:**

#### **By Priority:**
```javascript
// Critical and High only
{{ $json.issue.fields.priority.name === "Critical" || 
   $json.issue.fields.priority.name === "High" }}
```

#### **By Project:**  
```javascript
// Specific project only
{{ $json.issue.fields.project.key === "DEVOPS" }}
```

#### **By Component:**
```javascript
// Specific component
{{ $json.issue.fields.components.some(c => c.name === "Backend") }}
```

### **🎨 Custom Teams Messages:**

#### **Rich Adaptive Cards:**
```json
{
  "type": "AdaptiveCard",
  "version": "1.3",
  "body": [
    {
      "type": "TextBlock", 
      "text": "🎫 Jira Issue Update",
      "weight": "Bolder",
      "size": "Medium"
    },
    {
      "type": "FactSet",
      "facts": [
        {"title": "Issue:", "value": "{{ $json.issue.key }}"},
        {"title": "Summary:", "value": "{{ $json.issue.fields.summary }}"},
        {"title": "Status:", "value": "{{ $json.issue.fields.status.name }}"},
        {"title": "Assignee:", "value": "{{ $json.issue.fields.assignee?.displayName || 'Unassigned' }}"}
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.OpenUrl",
      "title": "View in Jira",
      "url": "{{ $json.issue.self.replace('/rest/api/3/issue/' + $json.issue.id, '/browse/' + $json.issue.key) }}"
    }
  ]
}
```

### **📊 Daily Summary Workflow:**

#### **Schedule Trigger Setup:**
```bash
1. Add "Schedule Trigger" node
2. Set trigger: "Every day at 9:00 AM"
3. Add "Jira" node to fetch issues:
   - JQL: "project = PROJ AND updated >= -1d"
   - Fields: summary, status, assignee, priority
4. Add "Function" node to format summary
5. Connect to Teams webhook
```

#### **Summary Template:**
```javascript
// Function node code:
const issues = $input.all();
const summary = {
  total: issues.length,
  critical: issues.filter(i => i.json.fields.priority.name === 'Critical').length,
  completed: issues.filter(i => i.json.fields.status.name === 'Done').length,
  in_progress: issues.filter(i => i.json.fields.status.name === 'In Progress').length
};

return {
  json: {
    text: `📊 **Daily Jira Summary - ${new Date().toLocaleDateString()}**
    
📋 Total Issues: ${summary.total}
🚨 Critical: ${summary.critical}  
✅ Completed: ${summary.completed}
🔄 In Progress: ${summary.in_progress}

[View Dashboard](https://yourcompany.atlassian.net/secure/Dashboard.jspa)`
  }
};
```

---

## 🎯 **Common Automation Scenarios:**

### **1. Bug Triage Workflow:**
```
Bug Created (Priority=Critical) 
  → @channel in #bug-triage
  → Direct message to Team Lead
  → Create Slack thread for discussion
```

### **2. Sprint Progress Tracking:**
```
Issue moved to "Done"
  → Calculate sprint progress %  
  → Update #sprint-progress channel
  → Notify Product Owner if milestone reached
```

### **3. SLA Monitoring:**
```
Issue aging > 3 days without update
  → Escalation notification
  → Direct message to assignee
  → CC manager if no response in 24h
```

### **4. Release Management:**
```
Issue labeled "release-ready"
  → Notify #release-management
  → Add to release tracking spreadsheet
  → Schedule deployment notification
```

---

## 🛠️ **Troubleshooting:**

### **Common Issues:**

#### **Teams Webhook Not Working:**
```bash
# Test webhook directly:
curl -X POST YOUR_TEAMS_WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d '{"text": "Test message"}'

# Check webhook URL format
✅ Correct: https://outlook.office.com/webhook/...
❌ Wrong: Missing https:// or malformed URL
```

#### **Jira Webhook Not Triggering:**
```bash
# Check webhook configuration:
1. Jira → Settings → Webhooks → Your webhook
2. Verify URL is accessible from internet
3. Check "Recent deliveries" for errors
4. Test with ngrok for local development
```

#### **n8n Workflow Errors:**
```bash
# Check execution log:
1. n8n → Executions tab
2. Click failed execution
3. Check error details
4. Common fixes:
   - Wrong JSON path: $json.issue.fields.priority.name
   - Missing fields: Add null checks
   - Webhook timeout: Increase timeout settings
```

### **Performance Optimization:**

#### **Reduce Noise:**
```javascript
// Filter out automated updates
{{ $json.user.accountType !== "atlassian" }}

// Only business hours notifications  
{{ new Date().getHours() >= 9 && new Date().getHours() <= 17 }}

// Skip minor updates
{{ !$json.changelog?.items?.some(item => 
   item.field === "description" || item.field === "comment") }}
```

---

## 📚 **Resources:**

### **Official Documentation:**
- [Jira Cloud REST API](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)
- [Teams Incoming Webhooks](https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook)
- [n8n Jira Node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.jira/)

### **Templates & Examples:**
- `workflows/jira-teams-automation.json` - Base workflow
- More templates: [n8n Community](https://n8n.io/workflows/)

---

## 🎉 **Success Checklist:**

- [ ] ✅ Teams webhooks created and tested
- [ ] ✅ Jira API token generated  
- [ ] ✅ n8n workflow imported and configured
- [ ] ✅ Jira webhooks configured and active
- [ ] ✅ End-to-end test completed successfully
- [ ] ✅ Filter rules customized for your needs
- [ ] ✅ Teams channels receiving notifications
- [ ] ✅ Team trained on new notification system

**🚀 You're now ready for automated Jira → Teams notifications!** 