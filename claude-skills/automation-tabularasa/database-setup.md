# Database Setup Guide - Tabula Rasa Automation

Complete guide for creating a dedicated MySQL user with minimal permissions for automated affinity management.

---

## Security Principle

**Least Privilege Access:** The `tabularasa_automation` user should only have permissions necessary for:
1. Reading ingestion statistics
2. Writing to affinity assignment tables
3. No destructive operations (DROP, DELETE, TRUNCATE)

---

## Prerequisites

- Root or admin MySQL access
- Access to `/devo-database` skill for Adolfo commands
- Jenkins credentials management access

---

## Step 1: Generate Strong Password

```bash
# Generate a 32-character random password
openssl rand -base64 32 | tr -d '/+=' | head -c 32
# Example output: kJ8mN2pQ4rT6vX9yZ1aB3cD5eF7gH0iL
```

**Store securely:** Password manager, Vault, Jenkins credentials

---

## Step 2: Create Database User

Connect to MySQL as admin:

```bash
source ~/.adolfo.yaml

# For APAC region
adolfo mysql --env ap_pro --dnname <master-db-hostname>

# For US region
adolfo mysql --env us_pro --dnname <master-db-hostname>

# For EU region
adolfo mysql --env eu_pro --dnname <master-db-hostname>
```

Create user with limited permissions:

```sql
-- ============================================
-- Tabula Rasa Automation User Setup
-- ============================================

-- 1. Create user (replace <PASSWORD> with generated password)
CREATE USER 'tabularasa_automation'@'%' 
IDENTIFIED BY '<PASSWORD>';

-- 2. Set password expiration (180 days)
ALTER USER 'tabularasa_automation'@'%' 
PASSWORD EXPIRE INTERVAL 180 DAY;

-- 3. Limit concurrent connections
ALTER USER 'tabularasa_automation'@'%' 
WITH MAX_USER_CONNECTIONS 5;

-- ============================================
-- Grant Read Permissions (Source Data)
-- ============================================
-- ⚠️  VERIFIED TABLE NAMES FROM PRODUCTION (APAC)
-- Confirmed: affinity, domain, machine, trunk tables exist

-- Domain information (638 domains in APAC)
GRANT SELECT ON logtrust.domain TO 'tabularasa_automation'@'%';

-- Machine (datanode) information (12 machines in APAC)
GRANT SELECT ON logtrust.machine TO 'tabularasa_automation'@'%';

-- Trunk information
GRANT SELECT ON logtrust.trunk TO 'tabularasa_automation'@'%';

-- Current affinity assignments (9,302 rows in APAC) - for backup
GRANT SELECT ON logtrust.affinity TO 'tabularasa_automation'@'%';

-- Machine groups
GRANT SELECT ON logtrust.machine_group TO 'tabularasa_automation'@'%';

-- Domain groups (optional)
GRANT SELECT ON logtrust.domain_group TO 'tabularasa_automation'@'%';

-- ============================================
-- Grant Write Permissions (Affinity Only)
-- ============================================

-- Allow INSERT for new affinity assignments
GRANT INSERT ON logtrust.affinity TO 'tabularasa_automation'@'%';

-- Allow UPDATE for existing affinity modifications
GRANT UPDATE ON logtrust.affinity TO 'tabularasa_automation'@'%';

-- ============================================
-- Explicitly Deny Destructive Operations
-- (Already denied by not granting, but explicit for clarity)
-- ============================================

-- ❌ NO DELETE permission
-- ❌ NO DROP permission
-- ❌ NO TRUNCATE permission
-- ❌ NO ALTER permission
-- ❌ NO CREATE permission
-- ❌ NO INDEX permission

-- ============================================
-- Apply Changes
-- ============================================

FLUSH PRIVILEGES;

-- ============================================
-- Verify Permissions
-- ============================================

SHOW GRANTS FOR 'tabularasa_automation'@'%';
```

**Expected Output:**
```sql
GRANT USAGE ON *.* TO 'tabularasa_automation'@'%'
GRANT SELECT ON `logtrust`.`domain` TO 'tabularasa_automation'@'%'
GRANT SELECT ON `logtrust`.`machine` TO 'tabularasa_automation'@'%'
GRANT SELECT ON `logtrust`.`trunk` TO 'tabularasa_automation'@'%'
GRANT SELECT ON `logtrust`.`affinity` TO 'tabularasa_automation'@'%'
GRANT SELECT ON `logtrust`.`machine_group` TO 'tabularasa_automation'@'%'
GRANT SELECT ON `logtrust`.`domain_group` TO 'tabularasa_automation'@'%'
GRANT INSERT, UPDATE ON `logtrust`.`affinity` TO 'tabularasa_automation'@'%'
```

---

## Step 3: Test User Access

### Test Read Permissions

```sql
-- Login as tabularasa_automation
mysql -h <db-host> -u tabularasa_automation -p logtrust

-- Test SELECT (should work)
SELECT COUNT(*) FROM logtrust.domain;        -- ✅ Should return domain count
SELECT COUNT(*) FROM logtrust.machine;       -- ✅ Should return machine count
SELECT COUNT(*) FROM logtrust.trunk;         -- ✅ Should return trunk count
SELECT COUNT(*) FROM logtrust.affinity;      -- ✅ Should return affinity count

-- Test JOIN (should work)
SELECT d.name, m.name, t.name
FROM logtrust.affinity a
JOIN logtrust.domain d ON a.domain_id = d.id
JOIN logtrust.trunk t ON a.trunk_id = t.id
JOIN logtrust.machine m ON t.machine_id = m.id
LIMIT 5;

-- Test INSERT (should work)
INSERT INTO logtrust.affinity (domain_id, trunk_id, creation_date)
VALUES ('test-domain-id', 1, NOW());

-- Test UPDATE (should work) 
UPDATE logtrust.affinity 
SET trunk_id = 2
WHERE domain_id = 'test-domain-id';

-- Clean up test data
DELETE FROM logtrust.affinity WHERE domain_id = 'test-domain-id';
-- ❌ This should FAIL with: ERROR 1142 (42000): DELETE command denied
```

### Test Denied Operations

```sql
-- These should all FAIL:

-- ❌ DELETE (should fail)
DELETE FROM logtrust.affinity WHERE domain_id = 'test';
-- ERROR 1142 (42000): DELETE command denied

-- ❌ DROP (should fail)
DROP TABLE logtrust.affinity;
-- ERROR 1142 (42000): DROP command denied

-- ❌ TRUNCATE (should fail)
TRUNCATE TABLE logtrust.affinity;
-- ERROR 1142 (42000): DROP command denied

-- ❌ ALTER (should fail)
ALTER TABLE logtrust.affinity ADD COLUMN test VARCHAR(100);
-- ERROR 1142 (42000): ALTER command denied

-- ❌ Access other databases (should fail)
USE mysql;
-- ERROR 1044 (42000): Access denied

-- ❌ Write to read-only tables (should fail)
INSERT INTO logtrust.domain (id, name) VALUES ('test', 'test.com');
-- ERROR 1142 (42000): INSERT command denied

UPDATE logtrust.machine SET name = 'test' WHERE id = 1;
-- ERROR 1142 (42000): UPDATE command denied
```

**If any denied operation succeeds, REVOKE permissions immediately!**

---

## Step 4: Store Credentials in Jenkins

### Using Jenkins UI

1. Navigate to: https://jenkins.devotools.com/credentials/
2. Click: "System" → "Global credentials" → "Add Credentials"
3. Fill details:
   - **Kind:** Username with password
   - **Scope:** Global
   - **Username:** `tabularasa_automation`
   - **Password:** (paste generated password)
   - **ID:** `tabularasa-db-credentials`
   - **Description:** Tabula Rasa automation database user (limited permissions)
4. Click "OK"

### Using Jenkins CLI (Alternative)

```bash
# Create credentials XML
cat > tabularasa-creds.xml <<'EOF'
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>tabularasa-db-credentials</id>
  <description>Tabula Rasa automation database user</description>
  <username>tabularasa_automation</username>
  <password><REPLACE_WITH_PASSWORD></password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF

# Upload to Jenkins
java -jar jenkins-cli.jar -s https://jenkins.devotools.com/ \
  -auth vikash.jaiswal:<API_TOKEN> \
  create-credentials-by-xml system::system::jenkins \
  < tabularasa-creds.xml

# Clean up
rm tabularasa-creds.xml
```

---

## Step 5: Configure Groovy Pipeline

Update the Groovy pipeline to use the new credentials:

```groovy
parameters {
  string(name: 'db_host', 
         defaultValue: 'mysql-master-ap-pro.devo.com', 
         description: 'Database host for SQL execution')
  
  string(name: 'db_port', 
         defaultValue: '3306', 
         description: 'Database port')
  
  string(name: 'db_name', 
         defaultValue: 'logtrust', 
         description: 'Database name')
  
  string(name: 'db_credentials_id', 
         defaultValue: 'tabularasa-db-credentials',  // ← New credential ID
         description: 'Jenkins credentials ID for database access')
}
```

---

## Step 6: Regional Database Hosts

Update default `db_host` values for each region:

### APAC (AWS)
```groovy
defaultValue: 'mysql-master-ap-southeast-1-pro.devo.com'
```

### US (AWS)
```groovy
defaultValue: 'mysql-master-us-east-1-pro.devo.com'
```

### EU (AWS)
```groovy
defaultValue: 'mysql-master-eu-west-1-pro.devo.com'
```

### EU (GCP)
```groovy
defaultValue: 'mysql-master-eu-west1-gcp-pro.devo.com'
```

---

## Step 7: Verify Connectivity from Jenkins

Create test job to verify DB access:

```groovy
stage('Test Database Connection') {
  steps {
    script {
      withCredentials([usernamePassword(
        credentialsId: 'tabularasa-db-credentials',
        usernameVariable: 'DB_USER',
        passwordVariable: 'DB_PASS'
      )]) {
        def testQuery = """
          mysql -h ${params.db_host} \
                -P ${params.db_port} \
                -u \${DB_USER} \
                -p\${DB_PASS} \
                ${params.db_name} \
                -e "SELECT 'Connection successful' AS status, COUNT(*) AS affinity_count FROM affinity_assignment;"
        """
        
        sh(script: testQuery)
      }
    }
  }
}
```

**Expected Output:**
```
+----------------------+----------------+
| status               | affinity_count |
+----------------------+----------------+
| Connection successful |           1234 |
+----------------------+----------------+
```

---

## Security Audit Checklist

- [ ] Password is 32+ characters, randomly generated
- [ ] Password stored in Jenkins credentials (not hardcoded)
- [ ] User has ONLY SELECT on source tables
- [ ] User has ONLY INSERT/UPDATE on affinity_assignment
- [ ] User CANNOT DELETE rows
- [ ] User CANNOT DROP tables
- [ ] User CANNOT TRUNCATE tables
- [ ] User CANNOT ALTER schema
- [ ] User CANNOT access other databases (mysql, sys, etc.)
- [ ] Connection limit set (MAX_USER_CONNECTIONS 5)
- [ ] Password expiration set (180 days)
- [ ] All regions configured with same user (ap, us, eu)
- [ ] Test connection successful from Jenkins
- [ ] Audit logging enabled for user actions

---

## Password Rotation

**Frequency:** Every 180 days (or quarterly)

**Process:**
```sql
-- 1. Generate new password
-- (Use openssl command from Step 1)

-- 2. Update MySQL user
ALTER USER 'tabularasa_automation'@'%' 
IDENTIFIED BY '<NEW_PASSWORD>';

-- 3. Update Jenkins credentials
-- (Use Jenkins UI: Credentials → Update password)

-- 4. Test connectivity
-- (Run test job from Step 7)

-- 5. Document rotation
-- (Update password manager, audit log)
```

---

## Rollback (Remove User)

If automation is deprecated or compromised:

```sql
-- 1. Revoke all permissions
REVOKE ALL PRIVILEGES, GRANT OPTION 
FROM 'tabularasa_automation'@'%';

-- 2. Drop user
DROP USER 'tabularasa_automation'@'%';

-- 3. Verify removal
SELECT User, Host FROM mysql.user WHERE User = 'tabularasa_automation';
-- (Should return empty result)

-- 4. Delete Jenkins credentials
-- (Jenkins UI: Credentials → Delete)

-- 5. Update Groovy pipeline
-- (Revert to manual SQL execution or alternative method)
```

---

## Troubleshooting

### Issue: Connection Refused

**Error:** `ERROR 2003 (HY000): Can't connect to MySQL server on 'host'`

**Cause:** Firewall, network issue, wrong hostname

**Solution:**
```bash
# Test network connectivity
ping mysql-master-ap-pro.devo.com

# Test MySQL port
telnet mysql-master-ap-pro.devo.com 3306

# Check DNS resolution
nslookup mysql-master-ap-pro.devo.com
```

### Issue: Access Denied

**Error:** `ERROR 1045 (28000): Access denied for user 'tabularasa_automation'@'host'`

**Cause:** Wrong password, user not created, wrong host

**Solution:**
```sql
-- Verify user exists
SELECT User, Host FROM mysql.user WHERE User = 'tabularasa_automation';

-- Check host whitelist (should be '%' for all hosts)
SELECT Host FROM mysql.user WHERE User = 'tabularasa_automation';

-- Reset password
ALTER USER 'tabularasa_automation'@'%' IDENTIFIED BY '<NEW_PASSWORD>';
```

### Issue: Permission Denied on SELECT

**Error:** `ERROR 1142 (42000): SELECT command denied`

**Cause:** Permissions not granted correctly

**Solution:**
```sql
-- Re-grant permissions
GRANT SELECT ON logtrust.domain_stats TO 'tabularasa_automation'@'%';
GRANT SELECT ON logtrust.datanode_capacity TO 'tabularasa_automation'@'%';
-- ... (repeat for all tables)

FLUSH PRIVILEGES;

-- Verify
SHOW GRANTS FOR 'tabularasa_automation'@'%';
```

### Issue: Cannot INSERT into affinity_assignment

**Error:** `ERROR 1142 (42000): INSERT command denied`

**Cause:** Write permissions not granted

**Solution:**
```sql
-- Grant write permissions
GRANT INSERT, UPDATE ON logtrust.affinity_assignment TO 'tabularasa_automation'@'%';
FLUSH PRIVILEGES;
```

---

## Monitoring User Activity

### Query User Connections

```sql
-- Show active connections
SELECT * FROM information_schema.processlist 
WHERE user = 'tabularasa_automation';

-- Count total connections
SELECT COUNT(*) FROM information_schema.processlist 
WHERE user = 'tabularasa_automation';
```

### Audit User Queries (if audit plugin enabled)

```sql
-- Show recent queries by user
SELECT 
  event_time,
  command_type,
  sql_text
FROM mysql.general_log
WHERE user_host LIKE '%tabularasa_automation%'
ORDER BY event_time DESC
LIMIT 100;
```

---

## Related Documentation

- **Main Skill:** `~/.claude/skills/automation-tabularasa/SKILL.md`
- **Rollback Guide:** `~/.claude/skills/automation-tabularasa/rollback-guide.md`
- **Devo Database Skill:** `~/.claude/skills/devo-database/`

---

**Last Updated:** 2026-04-23
**Status:** ✅ Production Ready
**Maintainer:** Vikash Jaiswal (vikash.jaiswal@devo.com)
