---
name: devo-database
description: Direct MySQL/Adolfo access to Devo logtrust database. Alert context management, period staggering, domain status, installation table. For Maqui queries use /devo-query.
argument-hint: "[region] [table] [query]"
tags: [mysql, adolfo, database, alert, logtrust]
---

## ⛔ CRITICAL — Never Use `find` on Datanodes

**NEVER run `find /var/logt ...` or any recursive file search on datanode hosts.**  
Use Maqui `system.delegated.internal.tableFile` or `system.delegated.internal.table` queries instead — they are indexed and safe.  
`find` on a datanode = hours of I/O, production query degradation, never completes usefully.

---

## Quick Start (sql alias)

Always source `.zshrc` first in Bash tool:

```bash
source ~/.zshrc && sql eu_pro -e "SELECT COUNT(*) FROM domain;"
source ~/.zshrc && sql usa_pro -e "SELECT COUNT(*) FROM domain;"
source ~/.zshrc && sql ap_pro -e "SELECT COUNT(*) FROM domain;"
source ~/.zshrc && sql us3_pro -e "SELECT COUNT(*) FROM domain;"
source ~/.zshrc && sql santander_eu -e "SELECT COUNT(*) FROM domain;"
```

---

## Regions & Connection

### sql alias — environment names

| Region | Correct Env Name | Wrong (never use) |
|---|---|---|
| EU Production | `eu_pro` | ~~eu~~, ~~eu_prod~~, ~~eu-pro~~ |
| US Production | `usa_pro` | ~~us_pro~~, ~~us~~, ~~us_prod~~ |
| APAC Production | `ap_pro` | ~~apac_pro~~, ~~apac~~, ~~apac_prod~~ |
| US3 Production | `us3_pro` | ~~us3_prod~~, ~~us3~~ |
| Santander | `santander_eu` | ~~san~~, ~~sant~~ |
| Canada | `ca_pro` | ~~ca~~, ~~canada~~ |
| Panda | `panda_pro` | ~~panda~~ |
| GCP Telefonica EU | `gcp_tef` | ~~gcp~~, ~~tef~~ |
| ME (NCSC Bahrain) | `me_pro` | ~~me~~, ~~ncsc~~ |

Credentials are in `~/.adolfo.yaml` (permissions 600). The `sql` alias calls `~/Documents/Scripts/mysql-wrapper.sh` which reads creds automatically — never expose passwords in commands.

### Adolfo connection

```bash
# Datanode management (enable/disable/readonly/list)
adolfo datanode enable   --env eu_pro  --dnname <datanode-name> --exec
adolfo datanode readonly --env usa_pro --dnname <datanode-name> --exec
adolfo datanode list     --env ap_pro  --dnname <datanode-name> --exec | grep -E '(ENABLED|DISABLED|READONLY|INCOMPLETE)'

# Domain affinity
adolfo affinity show -e eu_pro  --domains <domain> --trunks
adolfo affinity show -e usa_pro --domains <domain> --trunks

# Bulk loop pattern
for dn in $(seq 1 5); do
    adolfo datanode list --env ap_pro --dnname="datanode-${dn}-pro-cloud-shared-aws-ap-southeast-1" | grep -E '(ENABLED|DISABLED|READONLY|INCOMPLETE)'
done
```

---

## Key Tables

All queries run against the `logtrust` database.

| Table | Purpose |
|---|---|
| `alert_context` | Alert definitions (name, id) |
| `alert_context_subscription` | Alert delivery config: period, policy_type, status, params (JSON) |
| `pilot.contexts` | Runtime alert state (Pilot engine) |
| `installation` | Customer installation/delegation tree entries |
| `domain` | Domain records (name, id, email, status) |
| `machine` | Datanode records (name, id, status) |
| `trunk` | Trunk records per datanode |
| `affinity` | Domain-to-datanode affinity mapping |

---

## Alert Management Queries

### List alert periods for a customer

```bash
sql usa_pro -e "
SELECT
    ac.name,
    acs.id AS subscription_id,
    JSON_EXTRACT(acs.params, '\$.object.period') AS period_ms,
    ROUND(JSON_EXTRACT(acs.params, '\$.object.period') / 3600000, 2) AS period_hours,
    acs.policy_type,
    acs.status
FROM alert_context ac
JOIN alert_context_subscription acs ON ac.id = acs.alert_context_id
WHERE ac.name LIKE 'my.alert.curo%'
ORDER BY ac.name;
"
```

### Update alert period

```bash
# Set period to specific ms value
sql usa_pro -e "
UPDATE alert_context_subscription
SET params = JSON_SET(params, '\$.object.period', 14370000)
WHERE id = 294186;
"
```

**Period reference:** 1h = 3600000 ms, 4h = 14400000 ms, 8h = 28800000 ms, 24h = 86400000 ms

### Disable a single alert

```bash
sql eu_pro -e "
UPDATE alert_context_subscription
SET status = 'DISABLED'
WHERE id = <subscription_id>;
"
```

### Check alert by name (find subscription IDs)

```bash
sql eu_pro -e "
SELECT ac.id, ac.name, acs.id AS sub_id, acs.status, acs.policy_type,
       JSON_EXTRACT(acs.params, '\$.object.period') AS period_ms
FROM alert_context ac
JOIN alert_context_subscription acs ON ac.id = acs.alert_context_id
WHERE ac.name LIKE '%<alert_name>%';
"
```

---

## Period Staggering (Anti-Flooding)

When multiple alerts fire at the same time (same period, same start), they create a flood in XSOAR/SOAR. Stagger periods slightly to spread delivery.

### Pattern: stagger a group of 4h alerts

| Alert | Original (ms) | Staggered (ms) | Offset |
|---|---|---|---|
| Alert 1 | 14400000 (4h) | 14400000 | baseline |
| Alert 2 | 14400000 (4h) | 14370000 | −30s |
| Alert 3 | 14400000 (4h) | 14340000 | −60s |
| Alert 4 | 14400000 (4h) | 14310000 | −90s |

### Stagger update — batch example

```bash
sql usa_pro -e "
UPDATE alert_context_subscription
SET params = JSON_SET(params, '\$.object.period', 14370000)
WHERE id IN (294186);
"

sql usa_pro -e "
UPDATE alert_context_subscription
SET params = JSON_SET(params, '\$.object.period', 14340000)
WHERE id IN (294187);
"
```

### Rollback stagger (restore original period)

```bash
sql usa_pro -e "
UPDATE alert_context_subscription
SET params = JSON_SET(params, '\$.object.period', 14400000)
WHERE id IN (294186, 294187);
"
```

### Identify alerts at risk of flooding (same period, same customer)

```bash
sql usa_pro -e "
SELECT
    JSON_EXTRACT(acs.params, '\$.object.period') AS period_ms,
    COUNT(*) AS alert_count,
    GROUP_CONCAT(ac.name ORDER BY ac.name SEPARATOR ', ') AS alerts
FROM alert_context ac
JOIN alert_context_subscription acs ON ac.id = acs.alert_context_id
WHERE ac.name LIKE 'my.alert.<customer>%'
  AND acs.status = 'ENABLED'
GROUP BY period_ms
HAVING alert_count > 1
ORDER BY alert_count DESC;
"
```

---

## Domain & Installation Queries

### Find domain

```bash
sql eu_pro -e "SELECT id, name, email, status FROM domain WHERE name = 'cybersecurity@caixabank';"
sql eu_pro -e "SELECT id, name, email, status FROM domain WHERE name LIKE '%caixabank%';"
```

### Check domain status across regions

```bash
for env in eu_pro usa_pro ap_pro; do
    echo "=== $env ===" && source ~/.zshrc && sql $env -e "SELECT name, status FROM domain WHERE name = '<domain>';"
done
```

### Installation table — disable entry (offboarding / delegation tree)

```bash
# Check first
sql eu_pro -e "SELECT id, name, domain_id, enabled FROM installation WHERE name LIKE '%<customer>%';"

# Disable (requires confirmation — this is a data change)
sql eu_pro -e "UPDATE installation SET enabled = 0 WHERE id = <installation_id>;"
```

### Datanode (machine) status

```bash
sql eu_pro -e "SELECT id, name, status FROM machine WHERE name LIKE '%shared%' LIMIT 10;"
sql eu_pro -e "SELECT id, name, status FROM machine WHERE name = 'datanode-1-pro-cloud-shared-aws-eu-west-1';"
```

### Domain affinity via SQL

```bash
sql eu_pro -e "
SELECT d.name AS domain, m.name AS datanode, t.name AS trunk
FROM domain d
JOIN affinity a ON d.id = a.domain_id
JOIN machine m ON a.machine_id = m.id
JOIN trunk t ON a.trunk_id = t.id
WHERE d.name = 'cabot';
"
```

### List domains on a datanode

```bash
sql eu_pro -e "
SELECT d.name, d.email
FROM domain d
JOIN affinity a ON d.id = a.domain_id
JOIN machine m ON a.machine_id = m.id
WHERE m.name = 'datanode-1-pro-cloud-shared-aws-eu-west-1';
"
```

---

## Related Skills

| Skill | Use for |
|---|---|
| `/devo-query` | All Maqui/event data queries across regions |
| `/devo-alert` | Full alert lifecycle — Flow, Pilot, Cockpit, XSOAR anti-flooding rationale |
| `/devo-tools` | Mason/Lodge/Lomana, my.synthesis, myapp-loader architecture |
| `/devo-infra` | Kubernetes, Ansible, SOAR (LogicHub/XSOAR) |
