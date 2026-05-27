# Tabula Rasa Database User Creation - Status Tracker

**Goal:** Create `tabularasa` database user on all 5 production regions with limited permissions

**Date Started:** 2026-04-27  
**Status:** 🔄 In Progress (SQL scripts generated, awaiting admin credentials)

---

## Regions & Database Hosts

| # | Region | Adolfo Env | Database Hostname | Ansible Path |
|---|--------|-----------|-------------------|--------------|
| 1 | **APAC** | ap_pro | prod-apac.cluster-cdfmwxqfsdtx.ap-southeast-1.rds.amazonaws.com | aws/ap/pro |
| 2 | **US** | usa_pro | amazon.usa-east.dbpro.logtrust.net | aws/us/pro |
| 3 | **EU** | eu_pro | rds.shared.pro.aws.eu-west-1.devo.internal | aws/eu/pro |
| 4 | **US3** | us3_pro | database-us3.devo.internal | aws/us/pro3 |
| 5 | **ME** | me_pro | database.ncscbh.devo.internal | aws/me/ncscbh |

---

## User Credentials

**Username:** `tabularasa`  
**Password Policy:** NEVER expires, max 5 concurrent connections

| Region | Password | Generated | Status |
|--------|----------|-----------|--------|
| APAC | `3o6Qd5KWuhYbgVRmcWeVqF5D7iVyArrB` | ✅ 2026-04-27 | ⏳ Pending creation |
| US | `nnKAb88vfhR84G2NeJq9qkNPh2Bej2l6` | ✅ 2026-04-27 | ⏳ Pending creation |
| EU | `aa0eead79c4096b38c27916effe37051` | ✅ 2026-04-27 | ⏳ Pending creation |
| US3 | `27698d84dcfacfe60ba67ba3c65cb437` | ✅ 2026-04-27 | ⏳ Pending creation |
| ME | `K3IK1xdN1CwissHzZx42tPpH5S3HMvLX` | ✅ 2026-04-27 | ⏳ Pending creation |

---

## SQL Scripts Generated

All SQL scripts have been created in `/tmp/`:

| Region | File | Status |
|--------|------|--------|
| APAC | `/tmp/create-tabularasa-apac.sql` | ✅ Generated |
| US | `/tmp/create-tabularasa-us.sql` | ✅ Generated |
| EU | `/tmp/create-tabularasa-eu.sql` | ✅ Generated |
| US3 | `/tmp/create-tabularasa-us3.sql` | ✅ Generated |
| ME | `/tmp/create-tabularasa-me.sql` | ✅ Generated |

### SQL Script Contents

Each script performs:

```sql
-- 1. Create user with strong password
CREATE USER IF NOT EXISTS 'tabularasa'@'%' IDENTIFIED BY '<PASSWORD>';

-- 2. Set password to never expire
ALTER USER 'tabularasa'@'%' PASSWORD EXPIRE NEVER;

-- 3. Limit concurrent connections
ALTER USER 'tabularasa'@'%' WITH MAX_USER_CONNECTIONS 5;

-- 4. Grant READ permissions (source data)
GRANT SELECT ON logtrust.domain TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.machine TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.trunk TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.affinity TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.machine_group TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.domain_group TO 'tabularasa'@'%';

-- 5. Grant WRITE permissions (affinity table only)
GRANT INSERT, UPDATE ON logtrust.affinity TO 'tabularasa'@'%';

-- 6. Apply changes
FLUSH PRIVILEGES;

-- 7. Verify
SHOW GRANTS FOR 'tabularasa'@'%';
```

---

## Permissions Summary

### ✅ Granted Permissions

| Permission | Tables | Purpose |
|------------|--------|---------|
| **SELECT** | domain, machine, trunk, affinity, machine_group, domain_group | Read current state for affinity calculation |
| **INSERT** | affinity | Add new affinity assignments |
| **UPDATE** | affinity | Update existing affinity assignments |

### ❌ Denied Permissions (Security)

| Permission | Reason |
|------------|--------|
| DELETE | Prevent accidental data loss |
| DROP | Prevent table/database destruction |
| TRUNCATE | Prevent bulk data deletion |
| ALTER | Prevent schema changes |
| CREATE | Prevent table creation |
| INDEX | Prevent index changes |
| Access other databases | Limit scope to logtrust database only |

---

## Execution Status

### Current Issue

**Problem:** The credentials in `~/.adolfo.yaml` are for the `logtrust` application user, which lacks `CREATE USER` privilege.

**Current User:**
```sql
-- User: logtrust@%
-- Host: logtrust@10.7.128.199
-- Permissions: Application-level (no CREATE USER)
```

**Required:** Admin/root credentials for all 5 regions to execute user creation.

### Next Steps

1. **Obtain Admin Credentials**
   - Contact: DBA team / Infrastructure team
   - Required: MySQL admin user for each region
   - Purpose: Execute CREATE USER statements

2. **Execute SQL Scripts**
   ```bash
   # Example (once admin creds obtained):
   mysql -h <db-host> -u admin -p < /tmp/create-tabularasa-<region>.sql
   ```

3. **Verify User Creation**
   ```sql
   SHOW GRANTS FOR 'tabularasa'@'%';
   SELECT User, Host FROM mysql.user WHERE User='tabularasa';
   ```

4. **Test Connectivity**
   ```bash
   mysql -h <db-host> -u tabularasa -p<password> -D logtrust -e "SELECT COUNT(*) FROM affinity;"
   ```

---

## Manual Execution Commands

### APAC Region

```bash
# Option 1: Direct execution
mysql -h prod-apac.cluster-cdfmwxqfsdtx.ap-southeast-1.rds.amazonaws.com \
      -u <ADMIN_USER> -p < /tmp/create-tabularasa-apac.sql

# Option 2: Interactive
mysql -h prod-apac.cluster-cdfmwxqfsdtx.ap-southeast-1.rds.amazonaws.com \
      -u <ADMIN_USER> -p
# Then paste SQL from /tmp/create-tabularasa-apac.sql
```

### US Region

```bash
mysql -h amazon.usa-east.dbpro.logtrust.net \
      -u <ADMIN_USER> -p < /tmp/create-tabularasa-us.sql
```

### EU Region

```bash
mysql -h rds.shared.pro.aws.eu-west-1.devo.internal \
      -u <ADMIN_USER> -p < /tmp/create-tabularasa-eu.sql
```

### US3 Region

```bash
mysql -h database-us3.devo.internal \
      -u <ADMIN_USER> -p < /tmp/create-tabularasa-us3.sql
```

### ME Region

```bash
mysql -h database.ncscbh.devo.internal \
      -u <ADMIN_USER> -p < /tmp/create-tabularasa-me.sql
```

---

## Verification Checklist

After execution, verify each region:

- [ ] **APAC**
  - [ ] User created
  - [ ] Grants verified
  - [ ] Password never expires
  - [ ] Max connections = 5
  - [ ] Test SELECT on affinity table
  - [ ] Test INSERT on affinity table (then rollback)

- [ ] **US**
  - [ ] User created
  - [ ] Grants verified
  - [ ] Password never expires
  - [ ] Max connections = 5
  - [ ] Test SELECT on affinity table
  - [ ] Test INSERT on affinity table (then rollback)

- [ ] **EU**
  - [ ] User created
  - [ ] Grants verified
  - [ ] Password never expires
  - [ ] Max connections = 5
  - [ ] Test SELECT on affinity table
  - [ ] Test INSERT on affinity table (then rollback)

- [ ] **US3**
  - [ ] User created
  - [ ] Grants verified
  - [ ] Password never expires
  - [ ] Max connections = 5
  - [ ] Test SELECT on affinity table
  - [ ] Test INSERT on affinity table (then rollback)

- [ ] **ME**
  - [ ] User created
  - [ ] Grants verified
  - [ ] Password never expires
  - [ ] Max connections = 5
  - [ ] Test SELECT on affinity table
  - [ ] Test INSERT on affinity table (then rollback)

---

## After User Creation

Once all users are created, proceed to:

1. **Encrypt passwords with Ansible vault**
   ```bash
   ansible-vault encrypt_string '<PASSWORD>' --name 'tabularasa_mysql_password'
   ```

2. **Update vars.yml for each region**
   - File: `automation/ansible/environments/aws/<region>/pro/group_vars/all/vars.yml`
   - Add:
     ```yaml
     tabularasa_mysql_user: "tabularasa"
     tabularasa_mysql_password: !vault |
       $ANSIBLE_VAULT;1.2;AES256;cloudops
       <encrypted_password_here>
     ```

3. **Commit to git**
   ```bash
   git add automation/ansible/environments/
   git commit -m "Add tabularasa DB credentials to Ansible vault (5 regions)"
   ```

4. **Update Jenkins pipeline**
   - Remove `db_credentials_id` parameter
   - Use Ansible vault credentials

5. **Test execution**
   - Dry-run: `execute_sql=false`
   - Full run: `execute_sql=true`

---

## Contacts for Admin Credentials

**DBA Team:**
- Contact: #database-ops (Slack)
- Ticket: (Create Jira ticket if needed)

**Infrastructure Team:**
- Contact: #platform-ops (Slack)

**Security Team:**
- Contact: #security (Slack)
- Required: Approval for new database user

---

**Last Updated:** 2026-04-27  
**Status:** 🔄 In Progress  
**Owner:** Vikash Jaiswal (vikash.jaiswal@devo.com)  
**Next Action:** Obtain admin credentials for all 5 regions
