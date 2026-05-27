# Add Tabula Rasa Database Credentials to Ansible Vault

**Goal:** Store `tabularasa` DB credentials in Ansible vault and use them in both Ansible playbook and Jenkins pipeline (NO hardcoding, NO Jenkins credential store).

---

## Step 1: Add Credentials to Ansible Vault

### Option A: Add to vars.yml (Inline Vault - Recommended)

This follows the same pattern as `mysql_password`.

**File:** `automation/ansible/environments/aws/ap/pro/group_vars/all/vars.yml`

```bash
# Navigate to the directory
cd ~/Documents/Repository/automation/ansible/environments/aws/ap/pro/group_vars/all

# Create encrypted password string
ansible-vault encrypt_string 'YOUR_STRONG_PASSWORD_HERE' --name 'tabularasa_mysql_password'
```

**Output will be:**
```yaml
tabularasa_mysql_password: !vault |
  $ANSIBLE_VAULT;1.2;AES256;cloudops
  <encrypted_string_here>
```

**Add to vars.yml** (after line 107, after mysql_password):

```yaml
# Line 101-107 (existing mysql_password)
mysql_password: !vault |
  $ANSIBLE_VAULT;1.2;AES256;cloudops
  38653036383962383064633765303633343763353239306538633839333664623663633535323361
  6534343133613464306136646563313265636563663733640a376637353533363963336337336232
  35366132393266613537613230313462383632626434316666323961623937636663646630656264
  3762636462313830370a316564636165366163613662363130663038303938393438363761333033
  33313165386336323666313332643636633639666165336437656538326437333065

# NEW: Add tabularasa credentials (after line 107)
tabularasa_mysql_user: "tabularasa"
tabularasa_mysql_password: !vault |
  $ANSIBLE_VAULT;1.2;AES256;cloudops
  <paste_encrypted_password_here>
```

### Option B: Add to vault.yml (Separate Vault Variable)

**File:** `automation/ansible/environments/aws/ap/pro/group_vars/all/vault.yml`

```bash
# Edit vault file (requires vault password)
ansible-vault edit ~/Documents/Repository/automation/ansible/environments/aws/ap/pro/group_vars/all/vault.yml
```

**Add at the end of vault.yml:**
```yaml
vault_tabularasa_mysql_password: !vault |-
  $ANSIBLE_VAULT;1.2;AES256;cloudops
  <encrypted_password_here>
```

**Then reference in vars.yml:**
```yaml
tabularasa_mysql_user: "tabularasa"
tabularasa_mysql_password: "{{ vault_tabularasa_mysql_password }}"
```

---

## Step 2: Update Jenkins Pipeline to Use Ansible Vault

The Jenkins pipeline needs to read credentials from Ansible vault instead of Jenkins credential store.

### Current Code (Uses Jenkins Credentials)
**File:** `jenkinsfiles/jobs/job_ops_tabula_rasa_automated.groovy`

```groovy
// Lines 83-84 (REMOVE THIS)
string(name: 'db_credentials_id', defaultValue: 'tabularasa-db-credentials', ...)

// Lines 215-219 (CURRENT - Uses Jenkins credentials)
withCredentials([usernamePassword(
  credentialsId: params.db_credentials_id,
  usernameVariable: 'DB_USER',
  passwordVariable: 'DB_PASS'
)]) {
  def mysqldumpCmd = """
    mysqldump -h ${params.db_host} \
              -P ${params.db_port} \
              -u \${DB_USER} \
              -p\${DB_PASS} \
              ...
  """
}
```

### New Code (Uses Ansible Vault)

**Option 1: Read from Ansible vars at runtime**

```groovy
// In 'Backup Current Affinity' stage
stage('Backup Current Affinity') {
  when {
    expression { params.execute_sql == true }
  }
  steps {
    script {
      echo "============================================"
      echo "Stage: Backup Current Affinity (Safety)"
      echo "============================================"

      def timestamp = new Date().format('yyyy-MM-dd_HH-mm-ss', TimeZone.getTimeZone('UTC'))
      def backupFileName = "affinity-backup-${timestamp}.sql"
      def backupFilePath = "${actualTaraOutputDir}/${backupFileName}"

      echo "Creating backup of active affinity assignments..."
      echo "Backup file: ${backupFileName}"

      // Read credentials from Ansible vault variables
      def dbUser = sh(
        script: "cd ${WORKSPACE} && ansible localhost -m debug -a 'var=tabularasa_mysql_user' -i ${ansibleInventory} | grep -oP '\"tabularasa_mysql_user\": \"\\K[^\"]*'",
        returnStdout: true
      ).trim()

      def dbPass = sh(
        script: "cd ${WORKSPACE} && ansible localhost -m debug -a 'var=tabularasa_mysql_password' -i ${ansibleInventory} --ask-vault-pass | grep -oP '\"tabularasa_mysql_password\": \"\\K[^\"]*'",
        returnStdout: true
      ).trim()

      def mysqldumpCmd = """
        mysqldump -h ${params.db_host} \
                  -P ${params.db_port} \
                  -u ${dbUser} \
                  -p${dbPass} \
                  --no-create-info \
                  --skip-triggers \
                  --where="expiration_date IS NULL OR expiration_date > NOW()" \
                  ${params.db_name} affinity \
                  > ${backupFilePath}
      """

      def exitCode = sh(
        script: mysqldumpCmd,
        returnStatus: true
      )

      if (exitCode == 0) {
        echo "✅ Backup created successfully: ${backupFileName}"
        // ... rest of verification
      } else {
        error("❌ ERROR: Failed to create backup. Exit code: ${exitCode}")
      }
    }
  }
}
```

**Option 2: Pass credentials as Ansible extra vars**

```groovy
// In pipeline parameters section
parameters {
  string(name: 'ansible_branch', defaultValue: 'master', description: 'Branch to build')
  // ... other params ...
  
  // REMOVE: db_credentials_id parameter
  // Credentials will come from Ansible vault
}

// In 'Backup Current Affinity' stage
stage('Backup Current Affinity') {
  when {
    expression { params.execute_sql == true }
  }
  steps {
    script {
      echo "============================================"
      echo "Stage: Backup Current Affinity (Safety)"
      echo "============================================"

      def timestamp = new Date().format('yyyy-MM-dd_HH-mm-ss', TimeZone.getTimeZone('UTC'))
      def backupFileName = "affinity-backup-${timestamp}.sql"
      def backupFilePath = "${actualTaraOutputDir}/${backupFileName}"

      echo "Creating backup of active affinity assignments..."
      
      // Use Ansible to execute mysqldump with vault credentials
      ansiblePlaybook(
        playbook: "${ansiblePlaybookBasePath}tabula_rasa_backup.yml",
        installation: 'Ansible 2.10',
        inventory: "${ansibleInventory}",
        credentialsId: '3caaf92c-50c3-4c95-9ed8-777bdc409bd8',
        extras: "-e backup_file_path=${backupFilePath} -e db_host=${params.db_host}",
        colorized: true
      )
    }
  }
}
```

---

## Step 3: Create New Ansible Playbook for Backup/Execute (Option 2 Approach)

This is the **cleanest approach** - let Ansible handle all credential management.

**File:** `automation/ansible/playbooks/tabula_rasa_backup.yml`

```yaml
---
- name: Backup and Execute Tabula Rasa SQL
  hosts: localhost
  gather_facts: false

  vars:
    db_host: "{{ db_host_param | default('localhost') }}"
    db_port: "{{ db_port_param | default('3306') }}"
    db_name: "{{ db_name_param | default('logtrust') }}"
    db_user: "{{ tabularasa_mysql_user }}"
    db_password: "{{ tabularasa_mysql_password }}"
    backup_file_path: "{{ backup_file_path_param | default('affinity-backup.sql') }}"
    sql_file_path: "{{ sql_file_path_param | default('') }}"

  tasks:
    - name: Backup current affinity
      shell: |
        mysqldump -h {{ db_host }} \
                  -P {{ db_port }} \
                  -u {{ db_user }} \
                  -p{{ db_password }} \
                  --no-create-info \
                  --skip-triggers \
                  --where="expiration_date IS NULL OR expiration_date > NOW()" \
                  {{ db_name }} affinity \
                  > {{ backup_file_path }}
      register: backup_result
      no_log: true  # Don't log password

    - name: Verify backup was created
      stat:
        path: "{{ backup_file_path }}"
      register: backup_stat

    - name: Display backup size
      debug:
        msg: "Backup created: {{ backup_file_path }} ({{ (backup_stat.stat.size / 1024) | round(2) }} KB)"
      when: backup_stat.stat.exists

    - name: Execute SQL file (if provided)
      shell: |
        mysql -h {{ db_host }} \
              -P {{ db_port }} \
              -u {{ db_user }} \
              -p{{ db_password }} \
              {{ db_name }} \
              < {{ sql_file_path }}
      when: sql_file_path != ''
      register: execute_result
      no_log: true  # Don't log password

    - name: Verify SQL execution
      shell: |
        mysql -h {{ db_host }} \
              -P {{ db_port }} \
              -u {{ db_user }} \
              -p{{ db_password }} \
              {{ db_name }} \
              -e "SELECT COUNT(*) as recent_changes FROM affinity WHERE creation_date > NOW() - INTERVAL 5 MINUTE;"
      when: sql_file_path != ''
      register: verify_result
      no_log: true  # Don't log password

    - name: Display verification results
      debug:
        var: verify_result.stdout
      when: sql_file_path != ''
```

---

## Step 4: Update Jenkins Pipeline to Use New Playbook

**File:** `jenkinsfiles/jobs/job_ops_tabula_rasa_automated.groovy`

```groovy
// REMOVE this parameter (line 83)
// string(name: 'db_credentials_id', defaultValue: 'tabularasa-db-credentials', ...)

// REPLACE 'Backup Current Affinity' stage
stage('Backup Current Affinity') {
  when {
    expression { params.execute_sql == true }
  }
  steps {
    script {
      echo "============================================"
      echo "Stage: Backup Current Affinity (Safety)"
      echo "============================================"

      def timestamp = new Date().format('yyyy-MM-dd_HH-mm-ss', TimeZone.getTimeZone('UTC'))
      def backupFileName = "affinity-backup-${timestamp}.sql"
      def backupFilePath = "${actualTaraOutputDir}/${backupFileName}"

      echo "Creating backup using Ansible playbook..."

      ansiblePlaybook(
        playbook: "${ansiblePlaybookBasePath}tabula_rasa_backup.yml",
        installation: 'Ansible 2.10',
        inventory: "${ansibleInventory}",
        credentialsId: '3caaf92c-50c3-4c95-9ed8-777bdc409bd8',
        extras: "-e db_host_param=${params.db_host} -e db_port_param=${params.db_port} -e db_name_param=${params.db_name} -e backup_file_path_param=${backupFilePath}",
        colorized: true
      )

      echo "✅ Backup created successfully: ${backupFileName}"
    }
  }
}

// REPLACE 'Execute SQL on Database' stage
stage('Execute SQL on Database') {
  when {
    expression { params.execute_sql == true }
  }
  steps {
    script {
      echo "============================================"
      echo "Stage: Execute SQL on Database"
      echo "============================================"

      def sqlFileName
      if (params.tabula_rasa_type == 'rebalance') {
        sqlFileName = "rebalance-${params.machine_group}.sql"
      } else {
        sqlFileName = "tabula-rasa-${params.machine_group}.sql"
      }
      def sqlFileToExecute = "${actualTaraOutputDir}/${sqlFileName}"

      if (fileExists(sqlFileToExecute)) {
        echo "Found SQL file: '${sqlFileToExecute}'"
        echo "Executing SQL using Ansible playbook..."

        ansiblePlaybook(
          playbook: "${ansiblePlaybookBasePath}tabula_rasa_backup.yml",
          installation: 'Ansible 2.10',
          inventory: "${ansibleInventory}",
          credentialsId: '3caaf92c-50c3-4c95-9ed8-777bdc409bd8',
          extras: "-e db_host_param=${params.db_host} -e db_port_param=${params.db_port} -e db_name_param=${params.db_name} -e sql_file_path_param=${sqlFileToExecute}",
          colorized: true
        )

        echo "✅ SQL file '${sqlFileName}' executed successfully"
      } else {
        error("❌ ERROR: SQL file '${sqlFileToExecute}' not found. Cannot execute.")
      }
    }
  }
}
```

---

## Step 5: Repeat for All Regions

You need to add credentials for **each region**:

### APAC
```bash
cd ~/Documents/Repository/automation/ansible/environments/aws/ap/pro/group_vars/all

# Encrypt password
ansible-vault encrypt_string 'APAC_STRONG_PASSWORD' --name 'tabularasa_mysql_password'

# Edit vars.yml and add the encrypted string
```

### US
```bash
cd ~/Documents/Repository/automation/ansible/environments/aws/us/pro/group_vars/all

# Encrypt password (use same or different password)
ansible-vault encrypt_string 'US_STRONG_PASSWORD' --name 'tabularasa_mysql_password'

# Edit vars.yml and add the encrypted string
```

### EU
```bash
cd ~/Documents/Repository/automation/ansible/environments/aws/eu/pro/group_vars/all

# Encrypt password
ansible-vault encrypt_string 'EU_STRONG_PASSWORD' --name 'tabularasa_mysql_password'

# Edit vars.yml and add the encrypted string
```

---

## Complete Commands

### 1. Generate Strong Password

```bash
# Generate random password (20 characters)
openssl rand -base64 20

# Or use specific password
TABULARASA_PASSWORD="YourStrongPasswordHere123!"
```

### 2. Encrypt Password

```bash
# For APAC
cd ~/Documents/Repository/automation/ansible/environments/aws/ap/pro/group_vars/all
ansible-vault encrypt_string "${TABULARASA_PASSWORD}" --name 'tabularasa_mysql_password'
```

### 3. Edit vars.yml

```bash
# Open vars.yml in editor
vim vars.yml

# Add after line 107 (after mysql_password block):
# tabularasa_mysql_user: "tabularasa"
# tabularasa_mysql_password: !vault |
#   $ANSIBLE_VAULT;1.2;AES256;cloudops
#   <paste_encrypted_output_here>
```

### 4. Verify Variables

```bash
# Test that variables are accessible
cd ~/Documents/Repository/automation/ansible
ansible localhost -m debug -a "var=tabularasa_mysql_user" \
  -i environments/aws/ap/pro/hosts

ansible localhost -m debug -a "var=tabularasa_mysql_password" \
  -i environments/aws/ap/pro/hosts --ask-vault-pass
```

### 5. Commit Changes

```bash
cd ~/Documents/Repository/automation
git add ansible/environments/aws/ap/pro/group_vars/all/vars.yml
git add ansible/playbooks/tabula_rasa_backup.yml
git commit -m "Add tabularasa DB credentials to Ansible vault

- Added tabularasa_mysql_user and tabularasa_mysql_password to vars.yml
- Created tabula_rasa_backup.yml playbook for backup/execute operations
- All credentials stored in Ansible vault (no hardcoding)
"

cd ~/Documents/Repository/jenkinsfiles
git add jobs/job_ops_tabula_rasa_automated.groovy
git commit -m "Update Jenkins pipeline to use Ansible vault for DB credentials

- Removed db_credentials_id parameter
- Updated backup and execute stages to use Ansible playbook
- Credentials read from Ansible vault (no Jenkins credential store)
"
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│             Jenkins Pipeline (Groovy)                    │
│                                                          │
│  • Parameters: db_host, db_port, db_name                │
│  • NO hardcoded credentials                             │
│  • NO Jenkins credential store                          │
└──────────────────────┬──────────────────────────────────┘
                       │
                       │ Calls Ansible playbook with params
                       ▼
┌─────────────────────────────────────────────────────────┐
│         Ansible Playbook (tabula_rasa_backup.yml)       │
│                                                          │
│  • Reads: tabularasa_mysql_user                         │
│  • Reads: tabularasa_mysql_password                     │
│  • Executes: mysqldump / mysql                          │
└──────────────────────┬──────────────────────────────────┘
                       │
                       │ Reads variables from
                       ▼
┌─────────────────────────────────────────────────────────┐
│    Ansible Vault (vars.yml - Encrypted in Git)          │
│                                                          │
│  tabularasa_mysql_user: "tabularasa"                    │
│  tabularasa_mysql_password: !vault |                    │
│    $ANSIBLE_VAULT;1.2;AES256;cloudops                   │
│    <encrypted_password>                                 │
└──────────────────────┬──────────────────────────────────┘
                       │
                       │ Connects to
                       ▼
┌─────────────────────────────────────────────────────────┐
│          MySQL Database (Production RDS)                │
│                                                          │
│  • User: tabularasa                                     │
│  • Limited permissions (SELECT, INSERT, UPDATE)         │
└─────────────────────────────────────────────────────────┘
```

---

## Benefits of This Approach

✅ **No Hardcoding**
- All credentials stored in Ansible vault (encrypted)
- Version controlled with encryption
- No plain text passwords anywhere

✅ **No Jenkins Credential Store**
- Jenkins only calls Ansible playbooks
- Ansible handles all credential management
- Consistent with existing infrastructure

✅ **Easy to Rotate**
- Update encrypted password in vars.yml
- Commit to git
- No Jenkins configuration needed

✅ **Audit Trail**
- All changes tracked in git
- Encrypted diffs show when credentials changed
- No manual Jenkins UI changes

✅ **Consistent Across Regions**
- Same pattern for APAC, US, EU
- Easy to replicate
- Centralized credential management

---

## Testing

### Test 1: Verify Ansible Can Read Credentials

```bash
cd ~/Documents/Repository/automation/ansible

# Test variable access (will prompt for vault password)
ansible localhost -m debug -a "var=tabularasa_mysql_user" \
  -i environments/aws/ap/pro/hosts

ansible localhost -m debug -a "var=tabularasa_mysql_password" \
  -i environments/aws/ap/pro/hosts --ask-vault-pass
```

### Test 2: Test Backup Playbook Locally

```bash
cd ~/Documents/Repository/automation/ansible

ansible-playbook playbooks/tabula_rasa_backup.yml \
  -i environments/aws/ap/pro/hosts \
  -e "db_host_param=prod-apac-logtrust-database.cluster-cdpk1lzmfdj6.ap-southeast-1.rds.amazonaws.com" \
  -e "db_port_param=3306" \
  -e "db_name_param=logtrust" \
  -e "backup_file_path_param=/tmp/test-backup.sql" \
  --ask-vault-pass
```

### Test 3: Dry-Run Jenkins Job

```bash
# Trigger Jenkins job with execute_sql=false
jenkins_trigger RaD-Deployments/aws-ap-pro/tabula_rasa_auto_run \
  tabula_rasa_type=rebalance \
  machine_group=public \
  execute_sql=false

# Check that playbook runs without errors
```

---

## Security Considerations

🔒 **Vault Password Management**
- Store vault password in secure location (password manager)
- Jenkins needs vault password for playbook execution
- Use Jenkins credentials for Ansible vault password (ID: already exists)

🔒 **Credential Rotation**
- Update encrypted password every 90 days
- Test in dev/stage before production
- Update all regions simultaneously

🔒 **Access Control**
- Only authorized users can decrypt vault
- Git history shows who changed credentials
- Ansible vault password separate from DB password

---

## Rollback Procedure

If something goes wrong:

```bash
# 1. Revert vars.yml changes
cd ~/Documents/Repository/automation/ansible
git revert <commit-hash>

# 2. Revert Jenkins pipeline
cd ~/Documents/Repository/jenkinsfiles
git revert <commit-hash>

# 3. Restore from backup if database affected
mysql -h prod-apac-logtrust-database... \
      -u tabularasa -p < affinity-backup-*.sql
```

---

**Next Steps:**
1. ✅ Generate strong password for `tabularasa` user
2. ✅ Encrypt password with ansible-vault
3. ✅ Add to vars.yml for APAC
4. ✅ Create tabula_rasa_backup.yml playbook
5. ✅ Update Jenkins pipeline (remove Jenkins credentials)
6. ✅ Test locally
7. ✅ Test dry-run in Jenkins
8. ✅ Replicate for US and EU

---

**Last Updated:** 2026-04-27  
**Author:** Vikash Jaiswal  
**Status:** Ready for Implementation
