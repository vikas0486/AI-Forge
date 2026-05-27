# Tabula Rasa Automation - Implementation Plan

Step-by-step guide to deploy automated domain affinity management across all Devo regions.

---

## Phase 1: Database Setup (Week 1)

### 1.1 Create Limited-Access User

**For each region:** APAC, US, EU

```bash
# Connect to regional master database
source ~/.adolfo.yaml

# APAC
adolfo mysql --env ap_pro --dnname <master-db-hostname>

# US  
adolfo mysql --env us_pro --dnname <master-db-hostname>

# EU
adolfo mysql --env eu_pro --dnname <master-db-hostname>
```

**Execute user creation SQL:**
```sql
-- See: ~/.claude/skills/automation-tabularasa/database-setup.md
-- Follow Step 2: Create Database User

CREATE USER 'tabularasa_automation'@'%' IDENTIFIED BY '<STRONG_PASSWORD>';
GRANT SELECT ON logtrust.domain_stats TO 'tabularasa_automation'@'%';
GRANT SELECT ON logtrust.datanode_capacity TO 'tabularasa_automation'@'%';
GRANT SELECT ON logtrust.affinity_assignment TO 'tabularasa_automation'@'%';
GRANT INSERT, UPDATE ON logtrust.affinity_assignment TO 'tabularasa_automation'@'%';
FLUSH PRIVILEGES;
```

**Test access:**
```sql
-- Login as tabularasa_automation
mysql -h <db-host> -u tabularasa_automation -p logtrust

-- Verify read access
SELECT COUNT(*) FROM logtrust.affinity_assignment;

-- Verify cannot DELETE (should fail)
DELETE FROM logtrust.affinity_assignment WHERE domain = 'test';
-- ERROR 1142 (42000): DELETE command denied ✅
```

### 1.2 Store Credentials in Jenkins

1. Navigate to: https://devo-devtool.devotools.com/credentials/
2. Add credentials:
   - ID: `tabularasa-db-credentials`
   - Username: `tabularasa_automation`
   - Password: (generated password)
3. Repeat for each region (or use same credential globally)

---

## Phase 2: Master Job Creation (Week 1-2)

### 2.1 Create Master Jenkins Job

**Job Name:** `RaD-Deployments/tabula-rasa-execution`

**Job Type:** Pipeline

**Pipeline Script:**
```groovy
// Copy from: ~/.claude/skills/automation-tabularasa/groovy-improved.groovy
// Or from: ~/Documents/Repository/devo-devtoolfiles/jobs/job_ops_tabula_rasa_improved.groovy
```

**Configure Parameters:**
- All parameters from groovy file
- Set default `db_credentials_id`: `tabularasa-db-credentials`

### 2.2 Test Master Job Manually

**Test 1: Dry-Run Mode**
```bash
source ~/.jenkins/devo-devtool-helper.sh

jenkins_trigger RaD-Deployments/tabula-rasa-execution \
  region=ap \
  cloud=aws \
  enviroment=pro \
  tabula_rasa_type=rebalance \
  review_days=7 \
  machine_group=public \
  dry_run_only=true \
  db_host=mysql-master-ap-pro.devo.com
```

**Test 2: Manual Execution with Approval**
```bash
jenkins_trigger RaD-Deployments/tabula-rasa-execution \
  region=ap \
  cloud=aws \
  enviroment=pro \
  tabula_rasa_type=rebalance \
  review_days=7 \
  machine_group=public \
  skip_approval=false \
  execution_datetime="$(date -u '+%Y-%m-%d %H:%M')"
```

**Verify:**
1. Backup created successfully
2. SQL file generated
3. Manual approval stage triggered
4. SQL executed successfully
5. Affinity updated in database

---

## Phase 3: Wrapper Jobs Creation (Week 2)

### 3.1 APAC Region

**Weekly Rebalance:**
- Job: `RaD-Deployments/aws-ap-pro/tabula-rasa-weekly-rebalance`
- Schedule: `H 18 * * 6` (Every Saturday 18:00 UTC)
- Pipeline:
```groovy
pipeline {
  agent any
  triggers {
    cron('H 18 * * 6')
  }
  stages {
    stage('Trigger Master') {
      steps {
        build job: 'RaD-Deployments/tabula-rasa-execution',
              parameters: [
                string(name: 'region', value: 'ap'),
                string(name: 'cloud', value: 'aws'),
                string(name: 'enviroment', value: 'pro'),
                string(name: 'tabula_rasa_type', value: 'rebalance'),
                string(name: 'review_days', value: '7'),
                string(name: 'machine_group', value: 'public'),
                string(name: 'db_host', value: 'mysql-master-ap-pro.devo.com'),
                booleanParam(name: 'skip_approval', value: true),
                string(name: 'execution_datetime', value: sh(script: "date -u '+%Y-%m-%d %H:%M'", returnStdout: true).trim())
              ]
      }
    }
  }
}
```

**Biweekly Tabula Rasa:**
- Job: `RaD-Deployments/aws-ap-pro/tabula-rasa-biweekly-full`
- Schedule: `H 18 * * 0` (Every Sunday 18:00 UTC, biweekly via build discarder)
- Same pipeline, change `tabula_rasa_type` to `tabularasa`

### 3.2 US Region

**Weekly Rebalance:**
- Job: `RaD-Deployments/aws-us-pro/tabula-rasa-weekly-rebalance`
- Schedule: `H 12 * * 6` (Every Saturday 12:00 UTC)
- Change `region=us`, `db_host=mysql-master-us-pro.devo.com`

**Biweekly Tabula Rasa:**
- Job: `RaD-Deployments/aws-us-pro/tabula-rasa-biweekly-full`
- Schedule: `H 12 * * 0` (Every Sunday 12:00 UTC)

### 3.3 EU Region

**Weekly Rebalance:**
- Job: `RaD-Deployments/aws-eu-pro/tabula-rasa-weekly-rebalance`
- Schedule: `H 6 * * 6` (Every Saturday 06:00 UTC)
- Change `region=eu`, `db_host=mysql-master-eu-pro.devo.com`

**Biweekly Tabula Rasa:**
- Job: `RaD-Deployments/aws-eu-pro/tabula-rasa-biweekly-full`
- Schedule: `H 6 * * 0` (Every Sunday 06:00 UTC)

---

## Phase 4: Monitoring & Alerting (Week 3)

### 4.1 Create Monitoring Dashboards

**Grafana Dashboard:** Affinity Distribution
- Metric: Domain count per datanode
- Alert: Imbalance threshold >20% variance
- URL: grafana.devo.com/d/affinity-distribution

### 4.2 Setup Alerts

**Jenkins Job Failure:**
```groovy
// Add to post section of master job
post {
  failure {
    emailext (
      subject: "ALERT: Tabula Rasa Failed - ${params.region}",
      body: "Check: ${env.BUILD_URL}",
      to: "ops-team@devo.com"
    )
    
    // Slack notification
    slackSend (
      channel: '#devo-ops-alerts',
      color: 'danger',
      message: "⚠️ Tabula Rasa failed for ${params.region}"
    )
  }
}
```

### 4.3 Database Verification Queries

```sql
-- Check last affinity update
SELECT 
  MAX(updated_at) as last_update,
  COUNT(*) as total_assignments,
  COUNT(DISTINCT domain) as unique_domains,
  COUNT(DISTINCT datanode) as unique_datanodes
FROM logtrust.affinity_assignment
WHERE updated_at > NOW() - INTERVAL 7 DAY;

-- Check datanode balance
SELECT 
  datanode,
  COUNT(*) as domain_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM logtrust.affinity_assignment
GROUP BY datanode
ORDER BY domain_count DESC;
```

---

## Phase 5: Testing & Validation (Week 3-4)

### 5.1 Test Scenarios

**Test 1: Weekly Rebalance (Manual Trigger)**
```bash
# Trigger APAC rebalance
jenkins_trigger RaD-Deployments/aws-ap-pro/tabula-rasa-weekly-rebalance

# Monitor execution
jenkins_builds RaD-Deployments/aws-ap-pro/tabula-rasa-weekly-rebalance 1
jenkins_console RaD-Deployments/aws-ap-pro/tabula-rasa-weekly-rebalance <build-num> 200
```

**Verify:**
- [ ] Job triggered successfully
- [ ] Backup created
- [ ] SQL generated
- [ ] SQL executed
- [ ] Affinity updated
- [ ] No errors in logs

**Test 2: Biweekly Tabula Rasa (Manual Trigger)**
```bash
# Trigger US tabula rasa
jenkins_trigger RaD-Deployments/aws-us-pro/tabula-rasa-biweekly-full

# Verify complete recalculation
adolfo mysql -e "SELECT COUNT(DISTINCT domain) FROM logtrust.affinity_assignment;"
```

**Test 3: Rollback Scenario**
```bash
# Trigger with invalid parameters (to force failure)
jenkins_trigger RaD-Deployments/tabula-rasa-execution \
  region=eu \
  cloud=aws \
  enviroment=pro \
  tabula_rasa_type=rebalance \
  db_host=invalid-host.devo.com  # ← Force failure

# Verify rollback executed
jenkins_console RaD-Deployments/tabula-rasa-execution <build-num> | grep "Rollback"
```

**Test 4: Exclude Datanode**
```bash
# Exclude DN during maintenance
jenkins_trigger RaD-Deployments/tabula-rasa-execution \
  region=ap \
  cloud=aws \
  enviroment=pro \
  tabula_rasa_type=rebalance \
  exclude_alcohol="datanode-5-ap-pro,datanode-7-ap-pro"

# Verify excluded DNs have no new assignments
adolfo mysql -e "
  SELECT datanode, updated_at 
  FROM logtrust.affinity_assignment 
  WHERE datanode IN ('datanode-5-ap-pro', 'datanode-7-ap-pro')
  AND updated_at > NOW() - INTERVAL 1 HOUR;
"
```

### 5.2 Wait for First Scheduled Run

**First APAC Weekly Rebalance:** Saturday 18:00 UTC
**First US Weekly Rebalance:** Saturday 12:00 UTC
**First EU Weekly Rebalance:** Saturday 06:00 UTC

**Monitor:**
```bash
# Check if job triggered
jenkins_builds RaD-Deployments/aws-ap-pro/tabula-rasa-weekly-rebalance 5

# Check recent builds across all regions
for region in ap us eu; do
  echo "=== $region region ==="
  jenkins_builds RaD-Deployments/aws-${region}-pro/tabula-rasa-weekly-rebalance 1
done
```

---

## Phase 6: Production Rollout (Week 4)

### 6.1 Enable Auto-Approval (Optional)

Once confident, enable auto-approval for scheduled runs:

```groovy
// In wrapper job parameters
booleanParam(name: 'skip_approval', value: true)  // ← Auto-approve
```

### 6.2 Documentation

**Update Confluence:**
- Document automation architecture
- Add runbook for manual execution
- Add rollback procedures
- Add troubleshooting guide

**Update Team:**
- Send email to ops-team with overview
- Schedule knowledge transfer session
- Add to on-call runbook

---

## Rollback Plan (Emergency)

If automation causes issues:

### 1. Disable Scheduled Jobs

```bash
# Disable all wrapper jobs
# Jenkins UI → Job → Configure → Disable "Enable project"
```

### 2. Restore Previous Affinity

```bash
# Download backup from Jenkins artifacts
jenkins_console RaD-Deployments/tabula-rasa-execution <build-num> | grep "rollback-"

# Execute rollback SQL
source ~/.adolfo.yaml
adolfo mysql --env ap_pro < rollback-20260423-180000.sql

# Verify restoration
adolfo mysql -e "SELECT COUNT(*), MAX(updated_at) FROM logtrust.affinity_assignment;"
```

### 3. Revert to Manual Execution

```bash
# Use existing job without automation
jenkins_trigger RaD-Deployments/aws-ap-pro/tabula_rasa \
  tabula_rasa_type=rebalance \
  review_days=7 \
  machine_group=public
  
# Manually execute SQL as before
```

---

## Success Metrics

- [ ] All 3 regions have weekly rebalance scheduled
- [ ] All 3 regions have biweekly tabula rasa scheduled
- [ ] Database user created with limited permissions
- [ ] Jenkins credentials configured
- [ ] First manual execution successful (all regions)
- [ ] First scheduled execution successful (all regions)
- [ ] Rollback tested and working
- [ ] Monitoring dashboards created
- [ ] Alerts configured (email, Slack)
- [ ] Documentation published to Confluence
- [ ] Team trained on new automation

---

## Next Steps

1. **This Week:** Database setup (Phase 1)
2. **Next Week:** Master job + wrappers (Phase 2-3)
3. **Week 3:** Monitoring + testing (Phase 4-5)
4. **Week 4:** Production rollout (Phase 6)

---

## Contact

**Owner:** Vikash Jaiswal (vikash.jaiswal@devo.com)

**Related Skills:**
- `/automation-tabularasa` - Main documentation
- `/devo-database` - Database access
- `/devo-devtool` - Jenkins job management

---

**Last Updated:** 2026-04-23
**Status:** 🚧 Ready for Implementation
