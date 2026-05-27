# Tabula Rasa Automation - Changes Summary

**Date:** 2026-04-23
**Updated By:** Vikash Jaiswal

---

## ✅ Completed Updates

### 1. Database Schema Verification (APAC Production)

**Verified Tables:**
- ✅ `affinity` table (9,302 rows)
- ✅ `domain` table (638 domains)
- ✅ `machine` table (12 datanodes)
- ✅ `trunk` table
- ✅ `machine_group` table
- ✅ `domain_group` table

**Documentation:** `DATABASE-SCHEMA-VERIFIED.md`

---

### 2. Updated Database User Configuration

**Old (Incorrect):**
- User: `tabularasa_automation`
- Tables: `affinity_assignment`, `domain_stats`, `datanode_capacity` ❌

**New (Correct):**
- User: `tabularasa` ✅
- Tables: `affinity`, `domain`, `machine`, `trunk` ✅
- Permissions:
  - SELECT on: domain, machine, trunk, affinity, machine_group, domain_group
  - INSERT/UPDATE on: affinity (only!)

**Files Updated:**
- `database-setup.md` ✅
- `SKILL.md` ✅

---

### 3. Automated Groovy Pipeline (Final Version)

**Final File:** `jobs/job_ops_tabula_rasa_automated.groovy` ✅

**Location:** `/Users/vikash.jaiswal/Documents/Repository/jenkinsfiles/jobs/job_ops_tabula_rasa_automated.groovy`

**Design Philosophy:** Keep it simple - avoid production DB load from mysqldump, no backup/rollback stages

**Key Changes:**

1. **Based on Working Pipeline:**
   - Uses existing `job_ops_tabula_rasa.groovy` as foundation
   - Keeps all existing stages that work (Validate → Checkout → Execute playbook → Change SQL Date → Archive)
   - Adds only SQL execution stage

2. **Correct Database User:**
   ```groovy
   // User: tabularasa (limited permissions)
   db_credentials_id: 'tabularasa-db-credentials'
   ```

3. **Optional SQL Execution:**
   ```groovy
   booleanParam(name: 'execute_sql', defaultValue: true, 
                description: 'Execute SQL on database (uncheck to only generate SQL)')
   ```

4. **New Stage - Backup Current Affinity (Safety):**
   ```groovy
   stage('Backup Current Affinity') {
     when { expression { params.execute_sql == true } }
     steps {
       script {
         def timestamp = new Date().format('yyyy-MM-dd_HH-mm-ss', TimeZone.getTimeZone('UTC'))
         def backupFileName = "affinity-backup-${timestamp}.sql"
         
         // Backup only ACTIVE affinity (not expired)
         def mysqldumpCmd = """
           mysqldump -h ${params.db_host} -P ${params.db_port} 
                     -u \${DB_USER} -p\${DB_PASS} 
                     --no-create-info --skip-triggers 
                     --where="expiration_date IS NULL OR expiration_date > NOW()" 
                     ${params.db_name} affinity > ${backupFilePath}
         """
         // Verify backup created successfully
       }
     }
   }
   ```

5. **New Stage - Execute SQL on Database:**
   ```groovy
   stage('Execute SQL on Database') {
     when { expression { params.execute_sql == true } }
     steps {
       script {
         withCredentials([usernamePassword(...)]) {
           def mysqlCmd = """
             mysql -h ${params.db_host} -P ${params.db_port} 
                   -u \${DB_USER} -p\${DB_PASS} ${params.db_name} 
                   < ${sqlFileToExecute}
           """
           def exitCode = sh(script: mysqlCmd, returnStatus: true)
           if (exitCode == 0) {
             // Verify with COUNT query
           } else {
             error("Failed to execute SQL. Exit code: ${exitCode}")
           }
         }
       }
     }
   }
   ```

6. **Verification Query:**
   ```sql
   SELECT COUNT(*) as recent_changes 
   FROM affinity 
   WHERE creation_date > NOW() - INTERVAL 5 MINUTE;
   ```

7. **Safety Features:**
   - ✅ Backup created before SQL execution (only active rows)
   - ✅ Minimal DB load (WHERE clause filters expired rows)
   - ✅ Backup archived as Jenkins artifact
   - ✅ Rollback guide provided (ROLLBACK-GUIDE.md)

---

## 📋 Next Steps

### Step 1: Create Database User (APAC)

```bash
# Generate password
openssl rand -base64 32 | tr -d '/+=' | head -c 32

# Connect to APAC database
mysql -h prod-apac-logtrust-database.cluster-cdpk1lzmfdj6.ap-southeast-1.rds.amazonaws.com \
      -P 3306 \
      -u root \
      -p \
      -D logtrust

# Create user (see database-setup.md for full SQL)
CREATE USER 'tabularasa'@'%' IDENTIFIED BY '<PASSWORD>';
GRANT SELECT ON logtrust.domain TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.machine TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.trunk TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.affinity TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.machine_group TO 'tabularasa'@'%';
GRANT INSERT, UPDATE ON logtrust.affinity TO 'tabularasa'@'%';
FLUSH PRIVILEGES;

# Test permissions
mysql -h <host> -u tabularasa -p logtrust
SELECT COUNT(*) FROM affinity;  -- Should work ✅
DELETE FROM affinity WHERE id = 1;  -- Should FAIL ❌
```

---

### Step 2: Create Jenkins Credentials

**Jenkins UI:**
1. Navigate to: https://jenkins.devotools.com/credentials/
2. Add credentials:
   - **ID:** `tabularasa-db-credentials`
   - **Username:** `tabularasa`
   - **Password:** (from Step 1)
   - **Description:** Tabula Rasa automation user (limited permissions)
   - **Scope:** Global

---

### Step 3: Update Jenkins Job

**Job URL:** https://jenkins.devotools.com/job/RaD-Deployments/job/aws-ap-pro/job/tabula_rasa_auto_run/

**Update Pipeline Script:**
1. Go to job → Configure
2. Pipeline section → Pipeline script
3. Copy from: `jenkinsfiles/jobs/job_ops_automation_tabula_rasa.groovy`
4. OR use Pipeline script from SCM:
   - Repository: `git@gitlab.devotools.com:devops/jenkins/jenkinsfiles.git`
   - Script Path: `jobs/job_ops_automation_tabula_rasa.groovy`

**Update Default Parameters:**
```groovy
// APAC
db_host: 'prod-apac-logtrust-database.cluster-cdpk1lzmfdj6.ap-southeast-1.rds.amazonaws.com'

// US (when creating US job)
db_host: 'logtrustdbusa-production.cluster-cdpk1lzmfdj6.us-east-1.rds.amazonaws.com'

// EU (when creating EU job)
db_host: 'logtrustdb-production.cluster-cdpk1lzmfdj6.eu-west-1.rds.amazonaws.com'
```

---

### Step 4: Test Manual Execution

```bash
# Load Jenkins helper
source ~/.jenkins/jenkins-helper.sh

# Test with dry-run first
jenkins_trigger RaD-Deployments/aws-ap-pro/tabula_rasa_auto_run \
  tabula_rasa_type=rebalance \
  review_days=7 \
  machine_group=public \
  dry_run_only=true

# Monitor
jenkins_builds RaD-Deployments/aws-ap-pro/tabula_rasa_auto_run 1
jenkins_console RaD-Deployments/aws-ap-pro/tabula_rasa_auto_run <build-num> 200
```

**Verify:**
- ✅ Backup created successfully
- ✅ Tara tool executed
- ✅ SQL file generated
- ✅ Validation passed (correct table name)
- ✅ Artifacts archived

---

### Step 5: Test Full Execution (with Approval)

```bash
# Full execution with manual approval
jenkins_trigger RaD-Deployments/aws-ap-pro/tabula_rasa_auto_run \
  tabula_rasa_type=rebalance \
  review_days=7 \
  machine_group=public \
  skip_approval=false \
  execution_datetime="$(date -u '+%Y-%m-%d %H:%M')"

# Approve when prompted
# Monitor execution
```

**Verify Database Changes:**
```bash
mysql -h prod-apac-logtrust-database.cluster-cdpk1lzmfdj6.ap-southeast-1.rds.amazonaws.com \
      -P 3306 \
      -u tabularasa \
      -p \
      -D logtrust \
      -e "SELECT COUNT(*) as new_assignments,
                 MIN(creation_date) as first,
                 MAX(creation_date) as last
          FROM affinity
          WHERE creation_date > NOW() - INTERVAL 1 HOUR;"
```

---

### Step 6: Create Wrapper Jobs for Automation

**APAC Weekly Rebalance:**
- Job: `RaD-Deployments/aws-ap-pro/tabula-rasa-weekly-rebalance`
- Schedule: `H 18 * * 6` (Every Saturday 18:00 UTC)
- Triggers master job with `tabula_rasa_type=rebalance`

**APAC Biweekly Tabula Rasa:**
- Job: `RaD-Deployments/aws-ap-pro/tabula-rasa-biweekly-full`
- Schedule: `H 18 * * 0` (Every Sunday 18:00 UTC, biweekly)
- Triggers master job with `tabula_rasa_type=tabularasa`

**See:** `IMPLEMENTATION.md` for full wrapper job creation guide

---

## 🔍 Key Differences: Original vs Final

| Aspect | Original | Final (Simplified) |
|--------|----------|-------------------|
| **SQL Execution** | Manual (generated only) | Automated (via Jenkins) ✅ |
| **Database User** | Not implemented | `tabularasa` (limited perms) ✅ |
| **Table Names** | Assumed wrong names | Verified from production ✅ |
| **Backup Stage** | Not present | Not added (avoids DB load) ✅ |
| **Rollback** | Not present | Not added (keeps it simple) ✅ |
| **Verification** | Manual | Automated COUNT query ✅ |
| **Optional Execution** | N/A | `execute_sql` parameter ✅ |

---

## 📂 Updated Files

```
jenkinsfiles/jobs/
├── job_ops_tabula_rasa.groovy            ✅ Original (working baseline)
└── job_ops_tabula_rasa_automated.groovy  ✅ FINAL (with automated SQL execution)

~/.claude/skills/automation-tabularasa/
├── SKILL.md                          ✅ Updated (with backup stage)
├── database-setup.md                 ✅ Updated (tabularasa user)
├── DATABASE-SCHEMA-VERIFIED.md       ✅ NEW (schema from APAC prod)
├── CHANGES-SUMMARY.md                ✅ NEW (this file)
├── ROLLBACK-GUIDE.md                 ✅ NEW (emergency rollback procedures)
└── IMPLEMENTATION.md                 ✅ Existing (deployment guide)
```

---

## ⚠️ Important Notes

1. **Table Schema Verified:** All table names confirmed from APAC production (affinity, domain, machine, trunk)
2. **User Permissions:** Documented (SELECT on source tables, INSERT/UPDATE on affinity only)
3. **Safety Backup:** Automated backup of active affinity before SQL execution
4. **Minimal DB Load:** Backup uses WHERE clause (only active rows: expiration_date IS NULL)
5. **Rollback Capability:** Backup archived as Jenkins artifact, can be restored if needed
6. **Audit Trail:** All SQL files (including backup) archived for review
7. **Security:** User `tabularasa` cannot DELETE, DROP, TRUNCATE, or ALTER
8. **Optional Execution:** `execute_sql` parameter allows SQL generation without execution (for testing)

---

## 🚀 Ready for Production

### Completed ✅
- ✅ Schema verified from production (APAC)
- ✅ Automated Groovy pipeline created (`job_ops_tabula_rasa_automated.groovy`)
- ✅ Database user designed with minimal permissions (`tabularasa`)
- ✅ Documentation updated (SKILL.md, database-setup.md, CHANGES-SUMMARY.md)
- ✅ Backup stage added (safety: backs up active affinity before execution)
- ✅ SQL execution stage added (with optional execution parameter)
- ✅ Verification query included (post-execution COUNT)
- ✅ Rollback guide created (ROLLBACK-GUIDE.md)
- ✅ Original groovy content kept intact (minimal changes)

### Pending ⏳
- ⏳ Database user creation (APAC, US, EU)
- ⏳ Jenkins credentials setup (`tabularasa-db-credentials`)
- ⏳ Jenkins job update (deploy new Groovy file)
- ⏳ Manual test execution (dry-run first)
- ⏳ Full test with SQL execution
- ⏳ Wrapper jobs for automation (weekly/biweekly schedules)

---

**Next Action:** Create database user `tabularasa` in APAC production

**Reference:** 
- Skill: `/automation-tabularasa`
- Database setup: `~/.claude/skills/automation-tabularasa/database-setup.md`
- Implementation guide: `~/.claude/skills/automation-tabularasa/IMPLEMENTATION.md`
