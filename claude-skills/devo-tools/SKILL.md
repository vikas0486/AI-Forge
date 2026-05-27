---
name: devo-tools
description: Devo platform architecture — Mason/Lodge/Lomana metadata distribution, my.synthesis and my.app table lifecycle, myapp-loader service, lookup troubleshooting (missing data, udlu, blank grid), and Asilo. For running Maqui queries use /devo-query. For MySQL/Adolfo use /devo-database.
argument-hint: "[service] [issue]"
tags: [mason, lomana, my.synthesis, my.app, lodge, platform, architecture, lookup, udlu]
---

## Skill Boundaries

| What | Skill |
|------|-------|
| Run Maqui queries, Malote troubleshooting | **`/devo-query`** |
| MySQL / Adolfo / DB access | **`/devo-database`** |
| Platform architecture, Mason/Lomana, my.synthesis lifecycle | **this skill** |
| Lookup troubleshooting (missing data, blank grid, udlu) | **this skill** |
| Asilo aggregation engine, casparable ops, grain management | **this skill** |

---

## Mason Agent & Lomana Architecture

### Service Roles

| Service | Role | Creates files? | Distributes files? |
|---------|------|----------------|-------------------|
| **Lomana** | Lookup lifecycle orchestrator | ✅ Yes | ❌ No (delegates to Mason) |
| **Lodge** | Mason master — desired state registry | ❌ No | ❌ No |
| **Mason Agent** | Metadata file distributor (per datanode) | ❌ No | ✅ Yes |
| **RabbitMQ** | Message broker for async requests | ❌ No | ❌ No |

### How It Works

```
User/Webapp → RabbitMQ → Lomana (creates files) → Lodge (registers state)
                                                         ↓
                                              Mason Agents (datanodes)
                                              poll Lodge → download from S3
                                                         ↓
                                              Malote loads files → queryable
```

**Lomana:** Receives RabbitMQ requests → generates lookup/synthesis files → stores in S3 → tells Lodge  
**Mason Agent:** Runs on each datanode → polls Lodge every N minutes → downloads changed files from S3 → places locally  
**Lodge fix timing:** After fixing Lodge, wait **60+ minutes** for Dynatrace to clear (metric import is hourly).

### Alert Flow (Mason → Dynatrace)

1. Mason agents log failures → `siem.logtrust.mason.free`
2. Maqui query runs hourly → counts sustained failures
3. Metric imported to Dynatrace → alert fires if count > 0

**Key query (Dynatrace import):**
```
from siem.logtrust.mason.free where now() - 1h < eventdate < now()
where endswith(logger, 'Publisher'), msg -> 'failed=[agent:'
select re('.*failed=\\[agent:(.*)\\],.*') as Filter
select subs(msg, Filter, template("\\1"), msg) as Datanode
group every 10m by Datanode select count() as count where count > 10
group every 1h by Datanode select count() as count2 where count2 > 3
```

Run via: `source ~/.zshrc && maquieu "..."` (see `/devo-query`)

---

## Troubleshooting Mason Agent

### Failures Persist After Lodge Fix

**Problem:** Dynatrace still firing 30min after Lodge fix.  
**Why:** Metric import runs hourly; old errors still in 1h lookback window.  
**Fix:** Wait 60+ minutes for next import cycle, then verify with Maqui query (count = 0).

### Check Mason Agent on Datanode

```bash
# Service status
ssh <datanode> "systemctl status mason-agent"

# Lodge connectivity
ssh <datanode> "grep 'Lodge' /var/log/mason-agent/*.log | tail -20"

# S3 download errors
ssh <datanode> "grep -i 's3\|download\|failed' /var/log/mason-agent/*.log | tail -20"

# Health-check-agent monitoring mason
ssh <datanode> "grep mason-agent /var/log/health-check/agent.log | tail -10"
```

**Note:** Health-check-agent (`/automation-resilience-infra`) only detects process crashes — not Lodge connectivity or S3 download failures.

---

## Lookup Troubleshooting

### Architecture

Lookups (user-defined) flow through the same Mason/Lomana pipeline as my.synthesis:

```
Webapp → RabbitMQ → Lomana (generates file) → S3
                                                ↓
                                    Mason-Agent polls Lodge → downloads → udlu dir
                                                ↓
                                    Malote loads → lookup queryable
```

**Storage on datanode:** `/var/logt/data/malote/udlu/`  
**MaxMind GeoIP:** `/var/logt/data/malote/maxmind/`  
**Mason-Agent JVM:** `-Xms1G -Xmx1G`

### Symptoms

| Symptom | Likely cause |
|---------|-------------|
| Blank data grid in Webapp, red error top-right | Lookup file missing from datanodes or Malote failed to load it |
| Lookup works in some regions, not others | Mason-Agent down / Lodge unreachable on affected region datanodes |
| Lookup disappeared after instance type change | `/var/logt/data` mount failure wiped ephemeral instance store (see NVMe incident) |
| Lookup file present but still blank | Malote not reloaded after file update |
| IBM (Caixabank) datanodes affected | Check dedicated IBM cluster datanodes — Mason-Agent must be running on all nodes |

### Step 1 — Verify Lookup Deployed on Datanodes

```bash
# Check which datanodes have the lookup registered
source ~/.zshrc && maquieu "from system.delegated.internal.lookup where name = '<lookup_name>' and domain = '<domain>' group by instance(databaseinfo()) as datanode"

# For Caixabank (EU IBM cluster) — use homebaking@caixabank domain
source ~/.zshrc && maquieu "from system.delegated.internal.lookup where domain = 'homebaking@caixabank' and now()-1h <= eventdate < now() select name, instance(databaseinfo()) as datanode"
```

### Step 2 — Check Lomana Processed the Request

```bash
# Lomana activity for the lookup (last 24h)
source ~/.zshrc && maquieu 'from siem.logtrust.lomana.free where client = "self" and lookup = "<lookup_name>" and now()-24h <= eventdate < now() select eventdate, msg order by eventdate desc limit 20'

# Check for errors
source ~/.zshrc && maquieu 'from siem.logtrust.lomana.free where client = "self" and level = "ERROR" and now()-6h <= eventdate < now() select eventdate, lookup, msg order by eventdate desc limit 20'
```

### Step 3 — Check Mason-Agent on Affected Datanodes

```bash
# Service status (repeat for each affected datanode)
ssh <datanode> "sudo systemctl status mason-agent"

# Recent errors in mason-agent log
ssh <datanode> "sudo grep -i 'error\|failed\|exception' /var/log/mason-agent/*.log | tail -30"

# Check udlu dir exists and has files
ssh <datanode> "sudo ls -la /var/logt/data/malote/udlu/ | head -20"

# Check Lodge connectivity
ssh <datanode> "sudo grep 'Lodge' /var/log/mason-agent/*.log | tail -20"
```

### Step 4 — Check Malote Loaded the File

```bash
# Malote logs on the datanode
ssh <datanode> "sudo grep -i 'lookup\|udlu' /var/log/logtrust/malote*.log | tail -30"

# If file is present but Malote didn't reload, restart mason-agent (triggers reload)
# ⚠️ Confirm before running — systemctl restart requires explicit user approval
```

### Caixabank IBM Datanodes (ISM-16845)

Caixabank uses dedicated IBM cluster datanodes (EU, `homebaking@caixabank` domain). Mason-Agent must be running on **all** IBM datanodes.

```bash
# Find Caixabank IBM datanode hostnames
source ~/.zshrc && sql eu_pro -e "SELECT h.hostname, h.ip FROM host h JOIN installation i ON h.id_installation = i.id WHERE i.domain = 'homebaking@caixabank';"

# Check Mason-Agent on each IBM datanode
for dn in <dn1> <dn2> ...; do
  echo "=== $dn ==="; ssh $dn "sudo systemctl status mason-agent --no-pager | head -5"
done

# Check udlu dir content on IBM datanodes
ssh <caixabank-datanode> "sudo ls -la /var/logt/data/malote/udlu/ | wc -l"
```

### Recovery: Lookup File Present but Not Loaded

If `udlu/` has the file but the Webapp still shows blank:

```bash
# Touch the file to trigger Malote reload (Mason-Agent watches the directory)
ssh <datanode> "sudo touch /var/logt/data/malote/udlu/<lookup_file>"

# Or restart mason-agent — triggers full re-sync from Lodge
# ⚠️ Show command + confirm before running
```

### Recovery: Lookup File Missing from udlu/

Mason-Agent didn't download it. Options:

1. **Restart mason-agent** — it will re-poll Lodge and re-download missing files.
2. **Check S3** — Lomana stores files in S3; Mason-Agent fetches from there. If Lomana never processed it, re-trigger from Webapp.
3. **Check Lodge** — if Lodge is inconsistent, Mason-Agent won't know what to fetch.

```bash
# Check Lodge logs
ssh <datanode> "sudo journalctl -u mason_lodge.service --since '1 hour ago' | tail -30"
```

### Related Incident

**ISM-16845 (2026-05-19):** Caixabank `homebaking@caixabank` — lookup data blank, red error in Webapp. EU IBM dedicated datanodes. Assigned: Vikash Jaiswal.

---

## my.app & my.synthesis Table Lifecycle

### What Are These Tables

| Type | Pattern | Purpose |
|------|---------|---------|
| `my.app` | `my.app.<domain>.<name>` | Custom application log tables per customer |
| `my.synthesis` | `my.synthesis.<domain>.<name>` | Pre-aggregated views (LINQ query, periodic refresh) |

**Always use `client = "<domain>"` filter when querying** — 10x faster, prevents timeout. See `/devo-query` for query examples.

### my.synthesis Full Flow

```
User clicks in Webapp
    → RabbitMQ (mq_lomana_requests.lomana)
    → Lomana creates/generates files
    → S3 storage
    → Mason-Agent distributes to datanodes
    → Malote loads files → table queryable
```

**RabbitMQ queues:**
1. `mq_lomana_requests.lomana` — Webapp → Lomana
2. `mq_exchange_lomana_responses` — Lomana → Webapp
3. `mq_mason_lodge_notifications.lomana` — Mason/Lodge coordination

**⚠️ If RabbitMQ is down:** Cannot create/update/deploy tables. Existing tables still queryable.  
For RabbitMQ K8s troubleshooting → `/devo-infra` skill.

### Troubleshoot my.synthesis Creation Failures

```bash
# 1. Check Lomana received the request
source ~/.zshrc && maquieu 'from siem.logtrust.lomana.free where client = "self" and lookup = "<table_name>" and now()-24h <= eventdate < now() select eventdate, msg order by eventdate desc limit 20'

# 2. Check table deployed on datanodes
source ~/.zshrc && maquieu "from system.delegated.internal.lookup where lookup = '<table_name>' and domain = '<domain>' group by instance(databaseinfo()) as datanode"

# 3. Check MySQL record
source ~/.zshrc && sql eu_pro -e "SELECT * FROM casper_concept WHERE name LIKE '%<table_name>%' ORDER BY creation_date DESC LIMIT 5;"

# 4. Check RabbitMQ in K8s
source ~/.zshrc && kube get pods -n rabbitmq
source ~/.zshrc && kube logs -n rabbitmq rabbitmq-0 --tail=50
```

**Detailed docs:**
- Full workflow: `~/.claude/skills/devo-tools/my-synthesis-table-creation-workflow.md`
- Testing guide: `~/.claude/skills/devo-tools/create-test-my-synthesis-table.md`

---

## myapp-loader Service (my.app Generation)

**Purpose:** Runs on metamalote-general servers — syncs `my.app.*` table definitions from S3 to malote.  
**Current version:** v2.1.4 (deployed April 30, 2026 — CHG-10562)  
**Coverage:** ~55-75 metamalote-general servers, 10 environments (AWS US/EU/AP/CA/ME + GCP EU)  
**Service type:** cron-based  
**Log:** `/var/log/myapp-loader.log`  
**Script:** `/opt/logtrust/myapp-loader/myapp-loader.py`

### When my.app Tables Stop Generating

```bash
# Check loader log
ssh metamalote-1-pro-cloud-general-aws-us-east-1 "tail -50 /var/log/myapp-loader.log"

# Verify script version (should return 3 = v2.1.4 ✅)
ssh metamalote-1-pro-cloud-general-aws-us-east-1 "grep -c 'urllib_quote' /opt/logtrust/myapp-loader/myapp-loader.py"
```

**Deploy fix (from automation repo):**  
See `/devo-infra` skill → myapp-loader Role Deployment section for full Ansible commands.

**Known issue (RESOLVED v2.1.4):** Python 2/3 `urllib.quote` incompatibility — ISM-16277 (EU), ISM-16503 (US).

### Check Table Deployment vs DB Record

```bash
# Table in DB but not deployed? (domain may be inactive)
source ~/.zshrc && maquius "from system.delegated.internal.table where name ~ 'my.app.<domain>' select name, databaseinstance(null) as datanode"

# Check domain status in MySQL
source ~/.zshrc && sql usa_pro -e "SELECT domain, status FROM domain WHERE domain = '<domain>';"
# status=0 = inactive → tables won't deploy even if DB record exists
```

---

## Web UI Access

| Region | URL |
|--------|-----|
| EU | https://eu.devo.com/ |
| APAC | https://apac.devo.com/ |
| US | https://us.devo.com/ |
| US3 | https://us3.devo.com/ |
| Santander | https://dataplatform.san.devo.com/ |
| NCSC Bahrain | https://portal.hawk.ncsc.gov.bh/ |

Credentials: `~/.devo/credentials` (600 permissions)

---

## Asilo Aggregation Engine

> Full documentation: **[asilo.md](asilo.md)**

Quick links:
- EU host: `aso01-pro-eu-aws` (172.17.1.41) | Commander: `ssh aso01-pro-eu-aws "sudo su logtrust -s /bin/bash -c 'source /etc/profile.d/asilo-engine.sh && \$COMMANDER_HOME/bin/asilo-commander <CMD> \$COMMANDER_OPTIONS <args>'"`
- ⚠️ **Logs:** `/var/log/asilo-engine/asilo-engine.log` is GC only. Job status is in `siem.logtrust.asilo.activity` and `siem.logtrust.asilo.response` — query via Maqui, never SSH.
- ⚠️ **stop-delete-unregister:** NEVER run without explicit user confirmation — wipes all S3 casparable state permanently.

---

## Parser Deployment (matasmafias)

**Parsers** define how Devo ingests and structures data:
- `.mata` files — Table schema definitions (field names, types)
- `.mafia` files — Parsing logic (how to extract fields from raw events)

**Repository:** https://gitlab.com/devo_corp/data-ingestion/integrations/parsers/matasmafias

### Deployment Flow

```
GitLab MR → release-next → master
    ↓ GitLab CI (2-5 min): check_duplicates → gradlew_build → publish → Nexus
    ↓ Jenkins: Config2/matas/master → packages by region → S3: s3://lt-jenkins/matasmafias/master/
    ↓ Jenkins Regional Jobs (manual trigger per region)
    ↓ Ansible: matasmafias-v2.yml → downloads from S3 → syncs to /etc/logtrust/malote/defs/
    ↓ ⚠️ CRITICAL: Services DO NOT auto-reload — must manually restart
```

**Wait 5-10 min after master merge** before triggering regional Jenkins jobs (GitLab CI must finish publishing to S3 first).

### Jenkins Regional Jobs

| Job | Region |
|-----|--------|
| `deploy-matasmafias-aws-eu-pro` | EU |
| `deploy-matasmafias-aws-us-pro` | US |
| `deploy-matasmafias-aws-apac-pro` | APAC |
| `deploy-matasmafias-aws-us3-pro` | US3 |
| `deploy-matasmafias-aws-ca-pro` | Canada |
| `deploy-matasmafias-gcp-telefonica-eu-pro` | Telefónica EU |
| `deploy-matasmafias-gcp-caixabank-eu-pro` | Caixabank EU |
| `deploy-matasmafias-aws-santander-eu-pro` | Santander |

All at: https://jenkins.devotools.com/job/deploy-matasmafias/

### File Locations

```
/etc/logtrust/malote/defs/    # Parser definitions (307 subdirs)
/var/tmp/matasmafias/         # Ansible extraction staging
```

### Service Restart (REQUIRED after every deployment)

Both `metamalote` and `malote-controller` must be restarted — Ansible's directory "touch" is unreliable.

```bash
# All 10 EU metamalote servers
for i in {1..10}; do
  ssh metamalote-$i-pro-cloud-general-aws-eu-west-1 \
    "sudo systemctl restart metamalote && sudo systemctl restart malote-controller"
done

# Shared datanodes
for i in 1 2 3 7 8; do
  ssh datanode-$i-pro-cloud-shared-aws-eu-west-1 "sudo systemctl restart metamalote"
done

# US region
for i in {1..10}; do
  ssh metamalote-$i-pro-cloud-general-aws-us-east-1 \
    "sudo systemctl restart metamalote && sudo systemctl restart malote-controller"
done
```

### Troubleshooting

**"Unknown identifier `field_name`"** — Parser file exists but service not restarted → restart metamalote

**"Unknown table `table.name`"** — Parser files missing → re-run Jenkins deployment, then restart

**Works in US but not EU** — Check S3 timestamps for both regions; restart EU services

**Query routes to old datanode:**
```bash
# Error shows: Chain: [{/172.17.43.85:10100} -> {/172.17.36.160:10100}]
# Find hostname of the failing datanode IP
grep "172.17.36.160" /etc/hosts
# Restart that specific datanode
ssh <datanode-hostname> "sudo systemctl restart metamalote"
```

**Verify deployment:**
```bash
# S3 timestamp
aws s3 ls s3://lt-jenkins/matasmafias/master/matasmafias-awseu.tgz --profile production-limited

# File on server
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo stat /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.mata | grep Modify"

# Test query
source ~/.zshrc && maquieu 'from cef0.paloAltoNetworks.panOs where today()-1d <= eventdate < today() select * limit 1'
```

**Full details:** `~/.claude/skills/devo-tools/parsers/SKILL.md`

---

## Related Skills

- `/devo-query` — Maqui queries, Malote troubleshooting, customer data queries
- `/devo-database` — MySQL/Adolfo direct database access
- `/devo-infra` — Kubernetes, Ansible deployments, myapp-loader
- `/devo-devtool` — Jenkins CI/CD (parser deployment jobs)
- `/automation-resilience-infra` — Health-check-agent (monitors mason-agent process)
