# Database Credentials Location - Tabula Rasa

## Summary

There are **THREE** credential systems used by Tabula Rasa automation:

1. **Ansible Vault** (for MySQL database queries - `logtrust` user)
2. **Jenkins Credentials Store** (for automated SQL execution - `tabularasa` user)
3. **Malote/Maqui** (for ingestion data queries - `tabularasa` user, hardcoded)

---

## 1. Malote/Maqui - Reading Ingestion Data

### Location in Code
**File:** `automation/ansible/playbooks/tabula_rasa.yml`

```yaml
# Lines 40-41
"--malote.port=10100"
"--malote.user=tabularasa"
```

### Variables Definition
**File:** `automation/ansible/environments/<cloud>/<region>/<env>/group_vars/all/vars.yml`

**Example (APAC):** `automation/ansible/environments/aws/ap/pro/group_vars/all/vars.yml`

```yaml
# Line 58
malote: "metamalote-ap.devo.internal:10100"
malote_user: appweb  # This is for general Malote access
```

### Important Notes
- The `tabularasa` username is **hardcoded** in the playbook (line 41)
- This is a **read-only user** for Malote/Maqui queries
- No password is specified (Malote may use certificate-based auth or no auth for specific users)
- This user queries ingestion data to calculate domain volumes

### Malote Endpoints by Region

| Region | Malote/Metamalote Host | Port |
|--------|------------------------|------|
| **APAC** | metamalote-ap.devo.internal | 10100 |
| **US** | metamalote-us.devo.internal (likely) | 10100 |
| **EU** | metamalote-eu.devo.internal (likely) | 10100 |

---

## 2. Ansible Playbook - Reading Affinity Data

### Location in Code
**File:** `automation/ansible/playbooks/tabula_rasa.yml`

```yaml
# Lines 42-44
"--db.host={{ mysql_server_param }}:3306"
"--db.user=logtrust"
"--db.pwd={{ mysql_password_param }}"
```

### Variables Definition
**File:** `automation/ansible/environments/<cloud>/<region>/<env>/group_vars/all/vars.yml`

**Example (APAC):** `automation/ansible/environments/aws/ap/pro/group_vars/all/vars.yml`

```yaml
# Line 96
mysql_server: "database-apac.devo.com"

# Line 100-107
mysql_user: "logtrust"
mysql_password: !vault |
  $ANSIBLE_VAULT;1.2;AES256;cloudops
  38653036383962383064633765303633343763353239306538633839333664623663633535323361
  6534343133613464306136646563313265636563663733640a376637353533363963336337336232
  35366132393266613537613230313462383632626434316666323961623937636663646630656264
  3762636462313830370a316564636165366163613662363130663038303938393438363761333033
  33313165386336323666313332643636633639666165336437656538326437333065
```

### How Ansible Vault Works
- Credentials are **encrypted** in git repository
- Use `ansible-vault` to encrypt/decrypt values
- Requires vault password to decrypt during playbook execution

### Current Regions

| Region | mysql_server | File Path |
|--------|--------------|-----------|
| **APAC** | database-apac.devo.com | `automation/ansible/environments/aws/ap/pro/group_vars/all/vars.yml` |
| **US** | database-usa.devo.com (likely) | `automation/ansible/environments/aws/us/pro/group_vars/all/vars.yml` |
| **EU** | database-eu.devo.com (likely) | `automation/ansible/environments/aws/eu/pro/group_vars/all/vars.yml` |

---

## 3. Jenkins Pipeline - SQL Execution & Backup

### Location in Code
**File:** `jenkinsfiles/jobs/job_ops_tabula_rasa_automated.groovy`

```groovy
// Line 83 - Parameter definition
string(name: 'db_credentials_id', defaultValue: 'tabularasa-db-credentials', description: 'Jenkins credentials ID for database access')

// Lines 215-219 - Backup stage
withCredentials([usernamePassword(
  credentialsId: params.db_credentials_id,
  usernameVariable: 'DB_USER',
  passwordVariable: 'DB_PASS'
)]) {
  // mysqldump command uses ${DB_USER} and ${DB_PASS}
}

// Lines 285-289 - Execute SQL stage
withCredentials([usernamePassword(
  credentialsId: params.db_credentials_id,
  usernameVariable: 'DB_USER',
  passwordVariable: 'DB_PASS'
)]) {
  // mysql command uses ${DB_USER} and ${DB_PASS}
}
```

### Jenkins Credentials Store
**URL:** https://jenkins.devotools.com/credentials/

**Credential ID:** `tabularasa-db-credentials`
- **Type:** Username with password
- **Username:** `tabularasa`
- **Password:** (to be created)
- **Scope:** Global

---

## How to Add New `tabularasa` User Credentials

### Step 1: Create Database User (Already documented in `database-setup.md`)

```sql
-- Connect to production database
CREATE USER 'tabularasa'@'%' IDENTIFIED BY '<STRONG_PASSWORD>';

-- Grant limited permissions
GRANT SELECT ON logtrust.domain TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.machine TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.trunk TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.affinity TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.machine_group TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.domain_group TO 'tabularasa'@'%';
GRANT INSERT, UPDATE ON logtrust.affinity TO 'tabularasa'@'%';

FLUSH PRIVILEGES;
```

### Step 2: Add Credentials to Jenkins

#### Option A: Via Jenkins Web UI

1. Go to https://jenkins.devotools.com/credentials/
2. Click "Global credentials"
3. Click "Add Credentials"
4. Fill in:
   - **Kind:** Username with password
   - **Scope:** Global
   - **Username:** `tabularasa`
   - **Password:** `<STRONG_PASSWORD>` (from Step 1)
   - **ID:** `tabularasa-db-credentials`
   - **Description:** `Tabula Rasa DB credentials for automated SQL execution (limited permissions)`
5. Click "OK"

#### Option B: Via Jenkins CLI (if available)

```bash
# Create credential XML file
cat > tabularasa-cred.xml <<'EOF'
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>tabularasa-db-credentials</id>
  <description>Tabula Rasa DB credentials for automated SQL execution</description>
  <username>tabularasa</username>
  <password>YOUR_PASSWORD_HERE</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF

# Add to Jenkins
jenkins-cli create-credentials-by-xml system::system::jenkins _ < tabularasa-cred.xml

# Clean up
rm tabularasa-cred.xml
```

### Step 3: Per-Region Configuration

You need to add credentials for **each region**:

| Region | Credential ID | Database Host |
|--------|---------------|---------------|
| **APAC** | `tabularasa-db-credentials-apac` | prod-apac-logtrust-database.cluster-cdpk1lzmfdj6.ap-southeast-1.rds.amazonaws.com |
| **US** | `tabularasa-db-credentials-us` | logtrustdbusa-production.cluster-cdpk1lzmfdj6.us-east-1.rds.amazonaws.com |
| **EU** | `tabularasa-db-credentials-eu` | logtrustdb-production.cluster-cdpk1lzmfdj6.eu-west-1.rds.amazonaws.com |

**OR** use a single credential ID if the same username/password works across all regions:
- **ID:** `tabularasa-db-credentials` (same for all regions)
- Database host is passed as parameter to Jenkins job

---

## Where to Store Password (Options)

### ✅ Option 1: Jenkins Credentials Store (Recommended)
- **Location:** Jenkins credential store
- **Security:** Encrypted by Jenkins
- **Access:** Only via Jenkins jobs
- **Pros:** 
  - Built-in encryption
  - Audit trail
  - Easy rotation
  - No exposure in git
- **Cons:** 
  - Only accessible from Jenkins
  - Manual creation per Jenkins instance

### ✅ Option 2: Ansible Vault in Git (Current Method)
- **Location:** `automation/ansible/environments/<cloud>/<region>/<env>/group_vars/all/vault.yml`
- **Security:** Encrypted with ansible-vault
- **Access:** Anyone with vault password
- **Pros:** 
  - Version controlled
  - Same structure as existing credentials
  - Easy to replicate across regions
- **Cons:** 
  - Requires vault password management
  - Manual decryption needed

### ❌ Option 3: AWS Secrets Manager (Not Currently Used)
- **Location:** AWS Secrets Manager
- **Security:** AWS managed encryption
- **Pros:** 
  - Centralized secret management
  - Automatic rotation
  - Fine-grained IAM access
- **Cons:** 
  - Requires AWS SDK integration
  - Not currently implemented
  - Additional complexity

---

## Where MySQL Credentials are Stored in Git Repo

### Structure

```
automation/ansible/environments/
├── 000_cross_env_vars              # Global vault variables (monitoring, AWS keys, etc.)
└── <cloud>/<region>/<env>/
    └── group_vars/
        └── all/
            ├── vars.yml            # Plain text variables (hostnames, URLs)
            └── vault.yml           # Encrypted Ansible vault variables (passwords)
```

### Files with MySQL Credentials

| File | Type | Contents |
|------|------|----------|
| `000_cross_env_vars` | Vault | Global AWS keys, monitoring passwords, Nexus admin password |
| `group_vars/all/vars.yml` | Plain | `mysql_server`, `mysql_user`, reference to vault variable |
| `group_vars/all/vault.yml` | Vault | Encrypted `mysql_password` and other service passwords |

### Example Regions

```bash
# APAC
automation/ansible/environments/aws/ap/pro/group_vars/all/vars.yml
automation/ansible/environments/aws/ap/pro/group_vars/all/vault.yml

# US
automation/ansible/environments/aws/us/pro/group_vars/all/vars.yml
automation/ansible/environments/aws/us/pro/group_vars/all/vault.yml

# EU
automation/ansible/environments/aws/eu/pro/group_vars/all/vars.yml
automation/ansible/environments/aws/eu/pro/group_vars/all/vault.yml
```

---

## How to Add `tabularasa` User to Ansible Vault

If you want to store the new `tabularasa` user credentials in the same location as existing MySQL credentials:

### Step 1: Edit Vault File

```bash
# Navigate to region-specific vault
cd ~/Documents/Repository/automation/ansible/environments/aws/ap/pro/group_vars/all

# Edit encrypted vault (requires vault password)
ansible-vault edit vault.yml
```

### Step 2: Add New Variable

```yaml
# Add to vault.yml
vault_tabularasa_mysql_password: !vault |
  $ANSIBLE_VAULT;1.2;AES256;cloudops
  <ENCRYPTED_PASSWORD_HERE>
```

### Step 3: Reference in vars.yml

```yaml
# Edit vars.yml (plain text)
# Add after existing mysql_password (around line 108)

tabularasa_mysql_user: "tabularasa"
tabularasa_mysql_password: "{{ vault_tabularasa_mysql_password }}"
```

### Step 4: Encrypt Password

```bash
# Encrypt the password value
ansible-vault encrypt_string 'YOUR_STRONG_PASSWORD' --name 'vault_tabularasa_mysql_password'
```

### Step 5: Repeat for Other Regions

Repeat steps 1-4 for:
- US: `automation/ansible/environments/aws/us/pro/group_vars/all/`
- EU: `automation/ansible/environments/aws/eu/pro/group_vars/all/`

---

## Credentials Flow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                     Tabula Rasa Pipeline                          │
└──────────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐  ┌────────────────┐  ┌──────────────────┐
│ Query Malote  │  │ Query MySQL    │  │ Execute SQL      │
│ (Ingestion)   │  │ (Affinity)     │  │ & Backup         │
└───────────────┘  └────────────────┘  └──────────────────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐  ┌────────────────┐  ┌──────────────────┐
│ Hardcoded     │  │ Ansible Vault  │  │ Jenkins Creds    │
│               │  │ (Git)          │  │ Store            │
│ User:         │  │                │  │                  │
│  tabularasa   │  │ • mysql_server │  │ • User:          │
│ (no password) │  │ • mysql_user:  │  │   tabularasa     │
│               │  │   logtrust     │  │ • Pass:          │
│               │  │ • mysql_pass:  │  │   <encrypted>    │
│               │  │   <vault>      │  │                  │
└───────────────┘  └────────────────┘  └──────────────────┘
        │                   │                   │
        │                   └─────────┬─────────┘
        ▼                             ▼
┌───────────────┐          ┌──────────────────────┐
│ Malote/Maqui  │          │ MySQL Database       │
│ (Metamalote)  │          │ (Production RDS)     │
│               │          │                      │
│ Port: 10100   │          │ • logtrust user:     │
│ User:         │          │   Full permissions   │
│  tabularasa   │          │ • tabularasa user:   │
│               │          │   Limited (SELECT,   │
│               │          │   INSERT, UPDATE on  │
│               │          │   affinity only)     │
└───────────────┘          └──────────────────────┘
```

---

## Quick Reference

### Find MySQL Credentials

```bash
# Find all vault files
find ~/Documents/Repository/automation/ansible/environments \
  -name "vault.yml" -o -name "vault"

# Search for mysql references
grep -r "mysql_password\|mysql_server" \
  ~/Documents/Repository/automation/ansible/environments/aws/*/pro/group_vars/all/
```

### Edit Vault

```bash
# Decrypt and edit
ansible-vault edit ~/Documents/Repository/automation/ansible/environments/aws/ap/pro/group_vars/all/vault.yml

# View vault without editing
ansible-vault view ~/Documents/Repository/automation/ansible/environments/aws/ap/pro/group_vars/all/vault.yml
```

### Jenkins Credentials

```bash
# List Jenkins credentials (via CLI)
jenkins-cli list-credentials

# Test credential access from Jenkins
# Add to Groovy script in Jenkins console
com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
    com.cloudbees.plugins.credentials.common.StandardUsernamePasswordCredentials.class,
    Jenkins.instance,
    null,
    null
).findAll { it.id == 'tabularasa-db-credentials' }
```

---

## Security Best Practices

### ✅ DO
- Use strong passwords (16+ characters, mixed case, numbers, symbols)
- Store credentials in Jenkins credential store (encrypted at rest)
- Use Ansible vault for credentials in git (never plain text)
- Use limited database user (`tabularasa`) with minimal permissions
- Rotate credentials periodically (every 90 days)
- Audit credential access via Jenkins logs

### ❌ DON'T
- Store plain text passwords in git (even in .gitignore files)
- Use same password across multiple environments
- Share vault passwords via Slack/email
- Grant unnecessary database permissions
- Hardcode credentials in scripts or code

---

## Next Steps

1. ✅ Create `tabularasa` database user on APAC production RDS
2. ✅ Add credentials to Jenkins credential store (ID: `tabularasa-db-credentials`)
3. ✅ Test Jenkins job with new credentials
4. ✅ Replicate for US region
5. ✅ Replicate for EU region
6. ⏳ (Optional) Add credentials to Ansible vault for consistency

---

**Last Updated:** 2026-04-27  
**Author:** Vikash Jaiswal  
**Related:** `AUTOMATION-SUMMARY.md`, `database-setup.md`, `ROLLBACK-GUIDE.md`
