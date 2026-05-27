# Tabula Rasa - Rollback Guide

**Emergency rollback procedure for affinity changes**

---

## When to Rollback

Use this guide if:
- ❌ Affinity changes caused domain routing issues
- ❌ Unexpected domain redistribution occurred
- ❌ Performance degradation after execution
- ❌ Wrong SQL file was executed
- ❌ Need to revert to previous affinity state

---

## Prerequisites

Before starting rollback:
1. ✅ Backup SQL file available (archived in Jenkins artifacts)
2. ✅ Database access credentials (`tabularasa` user)
3. ✅ Approval from team lead or on-call engineer
4. ✅ Incident ticket created (document the issue)

---

## Rollback Procedure

### Step 1: Download Backup from Jenkins

**Jenkins Build URL Format:**
```
https://jenkins.devotools.com/job/RaD-Deployments/job/aws-ap-pro/job/tabula_rasa_auto_run/<build-number>/
```

**Using Jenkins CLI:**
```bash
source ~/.jenkins/jenkins-helper.sh

# Get recent builds
jenkins_builds RaD-Deployments/aws-ap-pro/tabula_rasa_auto_run 10

# Get artifacts list
jenkins_job RaD-Deployments/aws-ap-pro/tabula_rasa_auto_run/<build-num> | \
  jq -r '.artifacts[] | .fileName'

# Download backup SQL (replace <build-num>)
curl -u "vikash.jaiswal:<token>" \
  "https://jenkins.devotools.com/job/RaD-Deployments/job/aws-ap-pro/job/tabula_rasa_auto_run/<build-num>/artifact/ansible/playbooks/TabulaRasa/affinity-backup-*.sql" \
  -o /tmp/affinity-backup.sql
```

**Or download from Jenkins UI:**
1. Go to build URL
2. Click "Build Artifacts"
3. Download `affinity-backup-YYYY-MM-DD_HH-mm-ss.sql`

---

### Step 2: Verify Backup File

```bash
# Check backup file exists
ls -lh /tmp/affinity-backup.sql

# Check backup content (first 10 lines)
head -10 /tmp/affinity-backup.sql

# Expected output:
# INSERT INTO `affinity` VALUES (1,'domain-id-1',123,'2026-04-20 10:00:00',NULL);
# INSERT INTO `affinity` VALUES (2,'domain-id-2',124,'2026-04-20 10:00:00',NULL);
# ...

# Count SQL statements in backup
grep -c "INSERT INTO" /tmp/affinity-backup.sql
```

---

### Step 3: Connect to Database

**APAC:**
```bash
mysql -h prod-apac-logtrust-database.cluster-cdpk1lzmfdj6.ap-southeast-1.rds.amazonaws.com \
      -P 3306 \
      -u tabularasa \
      -p \
      -D logtrust
```

**US:**
```bash
mysql -h logtrustdbusa-production.cluster-cdpk1lzmfdj6.us-east-1.rds.amazonaws.com \
      -P 3306 \
      -u tabularasa \
      -p \
      -D logtrust
```

**EU:**
```bash
mysql -h logtrustdb-production.cluster-cdpk1lzmfdj6.eu-west-1.rds.amazonaws.com \
      -P 3306 \
      -u tabularasa \
      -p \
      -D logtrust
```

---

### Step 4: Check Current Affinity State

```sql
-- Count total active affinity
SELECT COUNT(*) as total_active
FROM affinity
WHERE expiration_date IS NULL;

-- Count recent changes (last 1 hour)
SELECT COUNT(*) as recent_changes
FROM affinity
WHERE creation_date > NOW() - INTERVAL 1 HOUR;

-- Check unique domains and trunks
SELECT
  COUNT(DISTINCT domain_id) as unique_domains,
  COUNT(DISTINCT trunk_id) as unique_trunks
FROM affinity
WHERE expiration_date IS NULL;

-- Exit MySQL
exit;
```

---

### Step 5: Execute Rollback

**⚠️ IMPORTANT:** This will restore affinity to the state from the backup!

```bash
# Execute rollback SQL
mysql -h prod-apac-logtrust-database.cluster-cdpk1lzmfdj6.ap-southeast-1.rds.amazonaws.com \
      -P 3306 \
      -u tabularasa \
      -p \
      -D logtrust \
      < /tmp/affinity-backup.sql

# Check exit code
echo $?
# Should return: 0 (success)
```

---

### Step 6: Verify Rollback Success

```bash
# Connect to database and run verification queries
mysql -h prod-apac-logtrust-database.cluster-cdpk1lzmfdj6.ap-southeast-1.rds.amazonaws.com \
      -P 3306 \
      -u tabularasa \
      -p \
      -D logtrust

# Run verification queries
mysql> SELECT COUNT(*) as total_active FROM affinity WHERE expiration_date IS NULL;
mysql> SELECT MAX(creation_date) as last_update FROM affinity;
mysql> SELECT COUNT(DISTINCT domain_id) as unique_domains FROM affinity WHERE expiration_date IS NULL;

# Compare with backup statistics (from Jenkins logs)
# Expected: counts should match backup state

# Exit
mysql> exit;
```

---

### Step 7: Test Domain Routing

**Pick 3-5 test domains and verify they route correctly:**

```bash
# Using Adolfo (check domain affinity)
source ~/.adolfo.yaml

# APAC
adolfo affinity show -e ap_pro --domains test-domain-1 --trunks
adolfo affinity show -e ap_pro --domains test-domain-2 --trunks

# US
adolfo affinity show -e us_pro --domains test-domain-1 --trunks

# EU
adolfo affinity show -e eu_pro --domains test-domain-1 --trunks
```

**Expected:**
- ✅ Domains route to correct datanodes (as per backup state)
- ✅ No routing errors in logs
- ✅ Ingestion working normally

---

### Step 8: Monitor System Health

**Check for 15-30 minutes after rollback:**

```bash
# Monitor Malote logs (check for routing errors)
source ~/Documents/Scripts/Maqui/maqui-helper-optimized.sh

# APAC ingestion
maqui_fast ap 'from siem.logtrust.malote.ingestion 
  where now() - 15m < eventdate 
  group by domain 
  select count() as events'

# Check for affinity errors
maqui_fast ap 'from siem.logtrust.malote.error 
  where now() - 15m < eventdate 
  group by message 
  select count() as errors'
```

**Watch Grafana:**
- Domain ingestion rate (should be stable)
- Datanode balance (should match pre-change state)
- No spike in errors

---

## Post-Rollback Actions

### 1. Document the Incident

**Jira ticket template:**
```
Title: [INCIDENT] Tabula Rasa Rollback - [Region] - [Date]

Description:
- Build number: #<build-num>
- Execution time: YYYY-MM-DD HH:MM UTC
- Rollback time: YYYY-MM-DD HH:MM UTC
- Reason for rollback: [describe issue]
- Impact: [domains affected, duration]
- Resolution: Restored from backup affinity-backup-YYYY-MM-DD_HH-mm-ss.sql

Root cause analysis:
- [To be investigated]

Action items:
- [ ] Review SQL generation logic
- [ ] Verify domain distribution algorithm
- [ ] Test in staging before next run
```

### 2. Notify Team

**Slack message:**
```
🔴 INCIDENT: Tabula Rasa rollback performed
Region: APAC
Time: 2026-04-23 17:30 UTC
Reason: [brief reason]
Status: ✅ Rolled back successfully
Impact: Minimal (15 minutes)
See Jira ticket: INFRA-XXXX
```

### 3. Investigate Root Cause

**Check Jenkins logs:**
```bash
source ~/.jenkins/jenkins-helper.sh

# Get full console output
jenkins_console_full RaD-Deployments/aws-ap-pro/tabula_rasa_auto_run <build-num> \
  > /tmp/failed-build.log

# Search for errors
grep -i "error\|fail\|exception" /tmp/failed-build.log

# Review generated SQL
jenkins_console RaD-Deployments/aws-ap-pro/tabula_rasa_auto_run <build-num> 500 | \
  grep -A 20 "INSERT INTO affinity"
```

**Review parameters:**
```bash
# Check build parameters
jenkins_parameters RaD-Deployments/aws-ap-pro/tabula_rasa_auto_run <build-num>

# Common issues:
# - Wrong execution_datetime
# - Incorrect machine_group
# - Missing exclude_alcohol for maintenance DNs
```

### 4. Prevent Future Issues

**Before next execution:**
- ✅ Test in staging environment first
- ✅ Review excluded datanodes (maintenance mode)
- ✅ Verify execution_datetime is correct
- ✅ Check domain count in generated SQL
- ✅ Compare with previous successful runs

---

## Common Rollback Scenarios

### Scenario 1: Wrong Execution Datetime

**Issue:** SQL executed with wrong timestamp, causing future-dated affinity

**Solution:**
```bash
# Rollback to backup
mysql < affinity-backup.sql

# Re-run with correct datetime
jenkins_trigger RaD-Deployments/aws-ap-pro/tabula_rasa_auto_run \
  execution_datetime="2026-04-23 17:00" \
  tabula_rasa_type=rebalance \
  execute_sql=true
```

### Scenario 2: Domain Routing Errors

**Issue:** Domains routing to wrong datanodes after execution

**Symptoms:**
- Ingestion failures
- 404 errors in Malote logs
- Grafana shows unbalanced distribution

**Solution:**
```bash
# Immediate rollback
mysql < affinity-backup.sql

# Investigate SQL generation
# Check if tara tool used correct parameters
```

### Scenario 3: Partial Execution Failure

**Issue:** SQL execution failed mid-way (transaction not completed)

**Symptoms:**
- Exit code != 0
- Partial affinity updates
- Inconsistent state

**Solution:**
```bash
# Rollback to backup (will restore full consistent state)
mysql < affinity-backup.sql

# Check for orphaned affinity
mysql -e "SELECT COUNT(*) FROM affinity WHERE domain_id NOT IN (SELECT id FROM domain);"

# Re-run job with execute_sql=true
```

### Scenario 4: Performance Degradation

**Issue:** Affinity changes caused performance issues

**Symptoms:**
- High CPU on specific datanodes
- Slow query times
- Increased latency

**Solution:**
```bash
# Rollback immediately
mysql < affinity-backup.sql

# Analyze domain distribution
mysql -e "
  SELECT 
    m.name as datanode,
    COUNT(DISTINCT a.domain_id) as domain_count
  FROM affinity a
  JOIN trunk t ON a.trunk_id = t.id
  JOIN machine m ON t.machine_id = m.id
  WHERE a.expiration_date IS NULL
  GROUP BY m.name
  ORDER BY domain_count DESC;
"

# Adjust domain_datanode_percentage before next run
```

---

## Emergency Contacts

**On-Call Engineer:**
- PagerDuty: https://devo.pagerduty.com/
- Slack: #ops-oncall

**Team Leads:**
- Platform: [Name] (@slack-handle)
- Database: [Name] (@slack-handle)
- DevOps: [Name] (@slack-handle)

**Escalation:**
- Critical production impact: Page on-call immediately
- Non-critical: Create Jira ticket, notify in #platform-ops

---

## Testing Rollback (Staging)

**Before production rollback, test in staging:**

```bash
# 1. Connect to staging database and restore
mysql -h prod-apac-logtrust-database-stage.cluster-cdpk1lzmfdj6.ap-southeast-1.rds.amazonaws.com \
      -P 3306 \
      -u tabularasa \
      -p \
      -D logtrust \
      < affinity-backup-test.sql

# 2. Verify restoration
mysql -h prod-apac-logtrust-database-stage.cluster-cdpk1lzmfdj6.ap-southeast-1.rds.amazonaws.com \
      -P 3306 \
      -u tabularasa \
      -p \
      -D logtrust \
      -e "SELECT COUNT(*) FROM affinity WHERE expiration_date IS NULL;"

# 3. Check domain routing (sample domains)
adolfo affinity show -e ap_stage --domains test-domain --trunks
```

---

## Rollback Checklist

**Before Rollback:**
- [ ] Backup SQL file downloaded from Jenkins
- [ ] Backup verified (correct timestamp, not corrupted)
- [ ] Incident ticket created
- [ ] Team notified in Slack
- [ ] Database credentials available
- [ ] Approval obtained (if business hours)

**During Rollback:**
- [ ] Current state documented (SQL queries)
- [ ] Backup executed successfully
- [ ] Exit code = 0
- [ ] Verification queries passed

**After Rollback:**
- [ ] Domain routing verified (3-5 test domains)
- [ ] System health monitored (15-30 minutes)
- [ ] Grafana dashboards checked
- [ ] No errors in Malote logs
- [ ] Incident ticket updated
- [ ] Post-mortem scheduled

---

**Last Updated:** 2026-04-23
**Maintainer:** Vikash Jaiswal (vikash.jaiswal@devo.com)
**Status:** ✅ Production Ready
