# Tabula Rasa Automation - Domain Affinity Management

Automated domain-to-datanode affinity rebalancing with SQL execution, safety backup, and rollback capabilities across all Devo regions (APAC, US, EU, US3, GCP-TEF).

**Status:** ✅ APAC Production (2026-05-08) | ⏳ EU/US/US3/GCP-TEF pending DB users

---

## Two Operation Modes

| Mode | Purpose | Frequency | Impact |
|------|---------|-----------|--------|
| **Rebalance** | Incremental load balancing | Weekly (Saturday) | Low disruption |
| **Tabula Rasa** | Complete recalculation | Biweekly (Sunday) | Clean slate |

---

## Pipeline Flow

```
1. Validate Parameters
   └─> Check datetime format, required params

2. Checkout Repository
   └─> Clone git@gitlab.com:devo_corp/platform/ansible/environments/automation.git

3. Execute Ansible Playbook (tabula_rasa.yml)
   └─> Download tara tool
   └─> Query Malote (ingestion data)
   └─> Query MySQL (affinity state)
   └─> Calculate optimal affinity
   └─> Generate SQL file (tabula-rasa-public.sql or rebalance-public.sql)

4. Change SQL Date (optional)
   └─> Override SET @change_date if execution_datetime param provided
   └─> Skips gracefully if no SQL file generated (cluster already balanced)

5. Backup Current Affinity
   └─> Runs only if execute_sql=true AND SQL file exists
   └─> mysqldump active affinity → affinity-backup-*.sql
   └─> Flags: --single-transaction --no-tablespaces --set-gtid-purged=OFF

6. Execute SQL on Database
   └─> Runs only if execute_sql=true AND SQL file exists
   └─> mysql < tabula-rasa-public.sql (or rebalance-public.sql)
   └─> Verify with COUNT query (affinity rows created last 5 min)

7. Archive Artifacts
   └─> CSV, SQL, JSON, Backup SQL saved to Jenkins artifacts
```

**Key behaviour:** If cluster is already balanced, tara generates no SQL file → stages 4/5/6 all skip gracefully (not an error).

---

## SQL Filename Convention

| tabula_rasa_type param | Generated SQL file |
|---|---|
| `rebalance` | `rebalance-public.sql` |
| `tabularasa` | `tabula-rasa-public.sql` (note: hyphen added by tara tool) |

The execute playbook maps `tabularasa` → `tabula-rasa` in the filename (fixed in MR #128).

---

## Jenkins Master Job

**URL:** https://jenkins.devotools.com/job/RaD-Deployments/job/tabula-rasa-automated/
**Groovy:** `jenkinsfiles/jobs/job_ops_tabula_rasa_automated.groovy`

**Key Parameters:**
| Parameter | Values | Notes |
|---|---|---|
| `region` | `ap`, `us`, `eu` | `us` covers both US and US3 |
| `cloud` | `aws`, `gcp` | gcp = GCP Telefonica |
| `enviroment` | `pro`, `pro3`, `tef` | pro3=US3, tef=GCP-TEF (typo kept for compatibility) |
| `tabula_rasa_type` | `rebalance`, `tabularasa` | |
| `machine_group` | `public` | default |
| `execution_datetime` | `YYYY-MM-DD HH:MM` | optional, SQL built-in future-date guard |
| `execute_sql` | `true`/`false` | false = dry-run (SQL generated but not executed) |

**Inventory path:** `ansible/environments/${cloud}/${region}/${enviroment}/hosts`
- APAC: `aws/ap/pro`
- EU: `aws/eu/pro`
- US: `aws/us/pro`
- US3: `aws/us/pro3`
- GCP TEF: `gcp/eu/tef`

---

## Quick Reference

### Trigger manually (APAC)
```bash
source ~/.jenkins/jenkins-helper.sh
jenkins_trigger RaD-Deployments/tabula-rasa-automated \
  region=ap cloud=aws enviroment=pro \
  tabula_rasa_type=rebalance machine_group=public \
  execute_sql=false
```

### Monitor
```bash
jenkins_builds RaD-Deployments/tabula-rasa-automated 5
jenkins_console RaD-Deployments/tabula-rasa-automated <build-num> 200
```

### Emergency Rollback (APAC)
```bash
# Download backup from Jenkins artifacts, then:
mysql -h database-apac.devo.com -P 3306 -u tabularasa -p logtrust < affinity-backup-*.sql
```

---

## Wrapper Jobs

**Location in Jenkins:** `Weekly-Schedules` folder per region
**Groovy source:** `jenkinsfiles/jobs/tabula-rasa-schedules/`

| Groovy File | Region | Schedule (UTC) |
|---|---|---|
| `ap_pro_rebalance_weekly.groovy` | APAC | Sat 18:00 |
| `ap_pro_tabularasa_biweekly.groovy` | APAC | Sun 18:00 (biweekly) |
| `eu_pro_rebalance_weekly.groovy` | EU | Sat 06:00 |
| `eu_pro_tabularasa_biweekly.groovy` | EU | Sun 06:00 (biweekly) |
| `us_pro_rebalance_weekly.groovy` | US | Sat 12:00 |
| `us_pro_tabularasa_biweekly.groovy` | US | Sun 12:00 (biweekly) |
| `us3_pro_rebalance_weekly.groovy` | US3 | Sat 09:00 |
| `us3_pro_tabularasa_biweekly.groovy` | US3 | Sun 09:00 (biweekly) |
| `gcp_tef_rebalance_weekly.groovy` | GCP TEF | Sat 06:00 |
| `gcp_tef_tabularasa_biweekly.groovy` | GCP TEF | Sun 06:00 (biweekly) |

**Wrapper parameters (configurable per build):**
- `cron_schedule` — override the automatic trigger expression
- `execution_time_utc` — time of day (HH:MM) for affinity changes (default: `10:00`)
- `execution_date_offset` — days ahead from trigger (default: `1` = next day)
- `review_days` — days of ingestion history to analyse (default: `7`)
- `machine_group` — target group (default: `public`; options: `shared`, `self-service`)

---

## Database Configuration

### DB Hosts

| Region | mysql_server | Status |
|---|---|---|
| **APAC** | `database-apac.devo.com` | ✅ tabularasa user created |
| **EU** | `rds.shared.pro.aws.eu-west-1.devo.internal` | ⏳ needs DB user |
| **US** | `amazon.usa-east.dbpro.logtrust.net` | ⏳ needs DB user |
| **US3** | `database-us3.devo.internal` | ⏳ needs DB user |
| **GCP TEF** | `10.132.0.3` (`alcohol_mysql_server`) | ⏳ needs DB user + vault password |

**Port:** 3306 | **Database:** logtrust

### Credentials Location
- **vars.yml:** `tabularasa_user: "tabularasa"` + `tabularasa_password: "{{ vault_tabularasa_password }}"`
- **vault.yml:** `vault_tabularasa_password: !vault | <encrypted>`
- **Path:** `automation/ansible/environments/<cloud>/<region>/<env>/group_vars/all/`

### DB User Creation Steps (per region)
```sql
CREATE USER 'tabularasa'@'%' IDENTIFIED BY '<PASSWORD>';
GRANT SELECT ON logtrust.domain TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.machine TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.trunk TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.machine_group TO 'tabularasa'@'%';
GRANT SELECT ON logtrust.domain_group TO 'tabularasa'@'%';
GRANT SELECT, INSERT, UPDATE ON logtrust.affinity TO 'tabularasa'@'%';
GRANT CREATE ROUTINE, ALTER ROUTINE, EXECUTE ON logtrust.* TO 'tabularasa'@'%';
FLUSH PRIVILEGES;
```

Then encrypt and add to vault:
```bash
ansible-vault encrypt_string '<PASSWORD>' --name 'vault_tabularasa_password' \
  --vault-password-file ~/.vault_cloudops_pass.txt
# Paste output into: automation/ansible/environments/<cloud>/<region>/<env>/group_vars/all/vault.yml
```

---

## DB User Permissions

| Permission | Scope |
|---|---|
| SELECT | domain, machine, trunk, affinity, machine_group, domain_group |
| INSERT, UPDATE | affinity |
| CREATE ROUTINE, ALTER ROUTINE, EXECUTE | logtrust.* (needed for stored procedures) |
| DELETE, DROP, TRUNCATE | Never granted |

---

## Pending

- ⏳ Create `tabularasa` DB user on EU, US, US3, GCP-TEF
- ⏳ Add `vault_tabularasa_password` to vault.yml for each region
- ⏳ Merge MR #129 after above is done
- ⏳ Create Jenkins wrapper jobs in UI for EU, US, US3, GCP-TEF
- ⏳ Test each region (dry-run first, then execute_sql=true)

---

## File Structure

```
jenkinsfiles/jobs/
├── job_ops_tabula_rasa_automated.groovy         # Master pipeline
└── tabula-rasa-schedules/
    ├── ap_pro_rebalance_weekly.groovy
    ├── ap_pro_tabularasa_biweekly.groovy
    ├── eu_pro_rebalance_weekly.groovy
    ├── eu_pro_tabularasa_biweekly.groovy
    ├── us_pro_rebalance_weekly.groovy
    ├── us_pro_tabularasa_biweekly.groovy
    ├── us3_pro_rebalance_weekly.groovy
    ├── us3_pro_tabularasa_biweekly.groovy
    ├── gcp_tef_rebalance_weekly.groovy
    └── gcp_tef_tabularasa_biweekly.groovy

automation/ansible/
├── playbooks/
│   ├── tabula_rasa.yml           # Main: generates SQL via tara tool
│   ├── tabula_rasa_backup.yml    # Backup: mysqldump active affinity
│   └── tabula_rasa_execute.yml   # Execute: mysql < sql_file + verify
└── environments/
    ├── aws/ap/pro/group_vars/all/vars.yml   ✅ tabularasa vars + vault
    ├── aws/eu/pro/group_vars/all/vars.yml   ✅ tabularasa vars (vault pending)
    ├── aws/us/pro/group_vars/all/vars.yml   ✅ tabularasa vars (vault pending)
    ├── aws/us/pro3/group_vars/all/vars.yml  ✅ tabularasa vars (vault pending)
    └── gcp/eu/tef/group_vars/all/vars.yml   ✅ tabularasa vars (vault pending)
```

---

## Related Skills

- `/devo-devtool` — Jenkins job management and monitoring
- `/devo-database` — Direct database access (Adolfo, MySQL)

---

**Confluence Doc:** https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5797740547/
**JIRA:** CHG-10560 / PLEN-8038
