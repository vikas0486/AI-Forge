<command-message>devo-tools</command-message>
<command-name>/devo-tools</command-name>

# Devo Platform - Reference

This README covers unique reference content not in SKILL.md: NASS client, data storage & retention model, Maqui syntax, and common tables. For Mason/Lomana architecture, Asilo, parsers, and myapp-loader, see `SKILL.md`.

---

## Web UI Access

| Region | URL | Status |
|--------|-----|--------|
| **EU** | https://eu.devo.com/ | Configured |
| **US** | https://us.devo.com/ | Configured |
| **APAC** | https://apac.devo.com/ | Configured |
| **US3** | https://us3.devo.com/ | Configured |
| **Telefonica** | https://sasr.devo.com/ | Configured |
| **Santander** | https://dataplatform.san.devo.com/ | Configured |
| **NCSC-Bahrain** | https://portal.hawk.ncsc.gov.bh/ | Configured |

Credentials stored in `~/.devo/credentials` (600 permissions).

---

## NASS Client - Domain Management Interface

**NASS** (Network Administration System Server) is Devo's web-based interface for domain administration, user management, and affinity configuration.

### NASS URLs by Environment

| Environment | NASS Client URL |
|-------------|-----------------|
| **EU** | https://nass-eu.devo.com/confDom |
| **US** | https://nass-us.devo.com/confDom |
| **APAC** | https://nass-ap.devo.com/confDom |
| **Santander** | https://nass.san.devo.com/confDom |

### NASS Credentials

Stored in `~/.devo/credentials` (NASS vars consolidated):
```bash
source ~/.devo/credentials
echo $NASS_EU_URL     # https://nass-eu.devo.com/confDom
echo $NASS_US_URL     # https://nass-us.devo.com/confDom
echo $NASS_APAC_URL   # https://nass-ap.devo.com/confDom
```
- Email: vikash.jaiswal@devo.com / Password: Devo@1432 (all regions)

### NASS Features

**Config Domains** tabs:
- **General**: Domain API keys, hostname, alias
- **Plans**: Data ingestion/retention plans
- **Invitations**: Invite new users
- **Tables**: Domain affinity (trunk assignment)
- **Finders**: Finder/search config
- **Roles**: User permissions (Administrator, User, etc.)
- **Menu Views**: Web UI customization
- **ELBs**: Load balancer config

**Config Resellers** - Manage reseller accounts and sub-domains.

### Grant User Access via NASS

**Method 1: NASS Web Interface (Preferred)**
```
1. Open: https://nass-{region}.devo.com/confDom
2. Login → Config domains → Select domain → Roles tab
3. Add user with desired role (Administrator, User, etc.)
4. User must logout/login to Devo Web UI to refresh session
```

**Method 2: MySQL Direct**
```bash
# Find domain ID
sql eu_pro -e "SELECT id, name FROM domain WHERE name = 'target_domain';"

# Find role ID
sql eu_pro -e "SELECT id, name, type FROM role_custom WHERE domain = 'domain-uuid' AND type = 'ADMIN';"

# Add user to domain
sql eu_pro -e "INSERT INTO user_domain (user_id, domain_id, role_custom, owner, status, creation_date, update_date) VALUES ('user-uuid', 'domain-uuid', role_id, 1, 0, NOW(), NOW());"
```

### NASS Architecture

- **nass-server**: Java/Tomcat on port 5092
- **nass-client**: Node.js on port 5091
- **Database**: MySQL for domain administration

Internal config (Ansible):
```yaml
nass_server: "nass-1.santander.cloud.shared.aws.eu-west-1.devo.internal"
nass_server_port: 5092
```

### Common NASS Use Cases

| Use Case | Navigation |
|----------|-----------|
| Verify user access | Config domains → domain → Roles tab |
| Manage domain affinity | Config domains → domain → Tables tab |
| Get domain API credentials | Config domains → domain → General tab |
| Fix "no policies/no assigned apps" | Roles tab → Add user as Administrator → user re-login |

---

## Data Storage Architecture & Retention Model

### Three-Tier Storage

```
HOT RETENTION (e.g., 90 days — on datanode)
  t00/yng (SSD, days 0-3)  →  t02/old (EBS, days 3-90)
        daily jobs move data yng → old
              ↓ after hot retention expires
COLD RETENTION (S3/LTS — off datanode, requires rehydration)
```

### Storage Tiers

**t00/yng (SSD)**
- Live ingestion, fastest queries
- Duration: `alcohol_partitioning_age` (typically 3-7 days)
- Path: `/var/logt/ebs*/b*/t00/YYYY/MM/DD/domain/table.log`

**t02/old (EBS)**
- Older active data, moved nightly from yng
- Duration: remainder of hot retention window
- Path: `/var/logt/ebs*/b*/t02/YYYY/MM/DD/domain/table.log`

**S3/LTS (Cold)**
- Archived by Barcenas after hot retention expires
- Not queryable without rehydration
- Buckets: `devo-barcenas-eu`, `devo-barcenas-us`, `devo-barcenas-ap`

### Path Naming Conventions

```bash
# Standard naming (most datanodes)
/var/logt/ebs{0-7}/b{00,01}/{tier}/{YYYY}/{MM}/{DD}/

# Alternative naming (some customers, e.g. TE Connectivity)
/var/logt/tr{0-7}/b{00,01}/{tier}/{YYYY}/{MM}/{DD}/
```

### Retention Hierarchy — CRITICAL RULE

**Table retention CANNOT exceed NASS hot retention** (confirmed by Devo Engineering).

```
NASS Hot Retention = Maximum Boundary
  └── Table Retention ≤ NASS retention (always)

Example: NASS=90d, Table=30d → table data archived at 30d  ✅
Example: NASS=90d, Table=180d → table STILL archived at 90d ❌
```

### When to Update NASS Retention

| Scenario | Action |
|----------|--------|
| Restore data within hot retention | No NASS change needed — data already on datanode |
| Restore data beyond hot retention (e.g. 180d with 90d NASS) | **Update NASS BEFORE restoring** (or Barcenas re-archives it on next run) |
| Permanent retention increase | Update NASS → new value |
| Temporary increase for investigation | Increase → restore → investigate → revert NASS → Barcenas auto-cleans |

**Temporary retention workflow:**
```
1. NASS → Config Domains → domain → Plans Tab → increase Hot Retention
   (e.g. 90d → 400d, wait 5-10 min for propagation)
2. Run rehydration from S3
3. Complete investigation/consulting period
4. NASS → revert Hot Retention to contract value
5. Next Barcenas nightly run archives excess data back to S3
```

**Verify hot retention (NASS):**
```
NASS → Config Domains → domain → Plans Tab → Hot Retention value
```

---

## Barcenas — Rehydration / Restore from Cold Storage (LTS)

**Confluence runbooks:**
- Technical how-to: https://devoinc.atlassian.net/wiki/spaces/CO/pages/3753017365/
- Process/triage guide: https://devoinc.atlassian.net/wiki/spaces/CSUP/pages/4660592648/

**S3 buckets by region:**
| Region | Bucket |
|--------|--------|
| EU | `devo-barcenas-eu` |
| US | `devo-barcenas-us` |
| APAC | `devo-barcenas-ap` |

### Triage Checklist (before starting)

- [ ] Confirm domain, region, table(s), date range, timezone
- [ ] Convert requested times to UTC (ET summer = UTC-4 / ET winter = UTC-5)
- [ ] Note: each UTC window may span 2 calendar days
- [ ] Confirm how long rehydrated data needs to be queryable (standard = 14 days)
- [ ] Notify Account Rep / CSM — **rehydration incurs cost to Devo**
- [ ] File ISM ticket if not already present (subject: `[Customer] Data Rehydration Request <date>`)

### Timezone Reference — ET → UTC

| Season | Offset | Example |
|--------|--------|---------|
| EDT (Mar–Nov) | UTC-4 | 00:00 ET = 04:00 UTC same day; 23:59 ET = 03:59 UTC next day |
| EST (Nov–Mar) | UTC-5 | 00:00 ET = 05:00 UTC same day; 23:59 ET = 04:59 UTC next day |

**Each 24-hr ET day spans 2 UTC calendar dates** — recount/rehydrate AGE filters must cover both.

### Step 1 — Extend NASS Hot Retention

Calculate days from today back to the earliest requested date, add buffer (e.g. +30 days).

```
NASS → Config Domains → <domain> → Plans Tab → Hot Retention → set to <N> days
Wait 5-10 min for propagation before running rehydration.
```

⚠️ Must be done BEFORE rehydration — otherwise Barcenas nightly job re-archives files immediately.

### Step 2 — Identify Datanodes

```bash
# Find which datanodes hold the customer's data
source ~/.zshrc && maquius 'from system.delegated.internal.table where name ~ "<table_name>" and client = "<domain>" select name, databaseinstance(null) as datanode group by datanode'

# Check disk space on each datanode
ssh <datanode> "sudo df -h | grep -E 'ebs|tr|nvme'"
ssh <datanode> "sudo ls -ld /var/logt/ebs*/b*/t*"
```

### Step 3 — Recount (estimate size before touching data)

SSH to datanode as logtrust, copy the example config and edit:

```bash
ssh <datanode>
sudo su logtrust
cp /opt/logtrust/barcenas/etc/recount.cl /opt/logtrust/barcenas/etc/recount-<customer>-<date>.cl
# Edit: set domain filter, table filter(s), AGE (from/to in UTC), uuid for tracking
chmod 755 /opt/logtrust/barcenas/etc/recount-<customer>-<date>.cl
chown logtrust: /opt/logtrust/barcenas/etc/recount-<customer>-<date>.cl
```

Run the recount:
```bash
/opt/logtrust/barcenas/bin/barcenas --config /opt/logtrust/barcenas/etc/recount-<customer>-<date>.cl
```

Check no daily/backup job is running first:
```bash
# On each datanode (via Ansible or loop)
ssh <datanode> "sudo ps aux | grep -i daily | grep -v grep"
```

### Step 4 — Monitor Recount

```bash
# Size estimate per datanode (replace sourceUuid with your uuid)
source ~/.zshrc && maquius 'from siem.logtrust.barcenas.recounted
  where weakhas(sourceUuid, "<uuid>")
  group by datanode
  select datanode, count() as records, sum(files) as files, humanSize(sum(bytes)) as total_size'

# Check for errors
source ~/.zshrc && maquius 'from siem.logtrust.barcenas.activity
  where weakhas(sourceUuid, "<uuid>") and level = "ERROR"
  select eventdate, datanode, message limit 20'

# Check recount finished
source ~/.zshrc && maquius 'from siem.logtrust.barcenas.activity
  where weakhas(sourceUuid, "<uuid>")
  where weakhas(message, "RECOUNT operation finished")
  select eventdate, datanode, message'
```

### Step 5 — Expand Disk If Needed

If recount shows not enough free space → expand EBS disk before proceeding.  
Reference: CloudOps EBS expansion procedure.

### Step 6 — Run Rehydrate

```bash
sudo su logtrust
cp /opt/logtrust/barcenas/etc/rehydrate.cl /opt/logtrust/barcenas/etc/rehydrate-<customer>-<date>.cl
# Edit: same filters as recount + partitions.from / partitions (source → destination datanode partitions)
# If rehydrating back to original datanode: partitions.from == partitions
chmod 755 /opt/logtrust/barcenas/etc/rehydrate-<customer>-<date>.cl
chown logtrust: /opt/logtrust/barcenas/etc/rehydrate-<customer>-<date>.cl

/opt/logtrust/barcenas/bin/barcenas --config /opt/logtrust/barcenas/etc/rehydrate-<customer>-<date>.cl
```

### Step 7 — Monitor Rehydrate

```bash
# Progress
source ~/.zshrc && maquius 'from siem.logtrust.barcenas.activity
  where weakhas(sourceUuid, "<uuid>")
  where weakhas(message, "REHYDRATE")
  select eventdate, datanode, message order by eventdate desc limit 20'

# Errors
source ~/.zshrc && maquius 'from siem.logtrust.barcenas.activity
  where weakhas(sourceUuid, "<uuid>") and level = "ERROR"
  select eventdate, datanode, message limit 20'

# Warnings (e.g. timeouts)
source ~/.zshrc && maquius 'from siem.logtrust.barcenas.activity
  where weakhas(sourceUuid, "<uuid>") and level = "WARN"
  select eventdate, datanode, message limit 20'

# Finished
source ~/.zshrc && maquius 'from siem.logtrust.barcenas.activity
  where weakhas(sourceUuid, "<uuid>")
  where weakhas(message, "REHYDRATE operation finished")
  group by datanode select datanode, max(eventdate) as completion_time'
```

### Step 8 — Revert NASS Retention (after customer is done)

```
NASS → Config Domains → <domain> → Plans Tab → Hot Retention → revert to original contract value
```

Barcenas nightly job will automatically re-archive excess data back to S3.

### Error Workarounds

**Files not rehydrated (individual file failures):**
- Download manually from S3:
  ```
  https://s3.console.aws.amazon.com/s3/object/devo-barcenas-us?region=us-east-1&prefix=<path>
  ```
- rsync to correct path on datanode, preserve permissions (`chown logtrust:logtrust`)
- Or rerun rehydration — recommended if only a few files

**Operation timeout warning:** Rerun is safe; Barcenas skips already-restored files.

### Past Reference Tickets

| Ticket | Customer | Scope | Size |
|--------|----------|-------|------|
| OP-29698 | `creditone@optivmdr` | `my.app.stealthbits.intercept`, Jan–May 2024 | — |
| OP-28396 | `azamara@optivmdr` | `cloud.aws.waf.logs`, 310 days cold | 470 GB |
| ISM-16793 | `motionpoint_corp@compassmsp` | 16 tables, 4 specific days (Aug/Oct/Dec 2025, Feb 2026) | — |

---

## Maqui Query Language

Maqui is Devo's LINQ-style query language. For query execution use `source ~/.zshrc && maquieu "query"` (or region alias).

### Basic Syntax

```maqui
from <table>
where <filter_conditions>
select <fields>
group by <field>
```

### Query Components

| Component | Purpose | Example |
|-----------|---------|---------|
| `from` | Data source | `from siem.logtrust.mason.free` |
| `where` | Filter | `where eventdate > now() - 1h` |
| `select` | Fields/transforms | `select count() as count` |
| `group` | Aggregate | `group every 1h by Datanode` |
| `re()` | Regex extraction | `re('.*failed=\\[agent:(.*)\\].*')` |
| `subs()` | String substitution | `subs(msg, Filter, template("\\1"), msg)` |

### Time Functions

```maqui
now()                                          # current timestamp
now() - 1h / now() - 24h / now() - 7d        # relative time
now() - 1h < eventdate < now()                # last hour (range)
"2026-01-01" <= eventdate < "2026-02-01"      # absolute date range
```

### String Operators

```maqui
msg -> "error"           # contains (case-insensitive)
msg ->> "ERROR"          # contains (case-sensitive)
startswith(msg, "Failed")
endswith(msg, ".log")
toktains(msg, "token")   # token contains
weakhas(msg, "text")     # weak contains
msg ~ "regex.*pattern"   # regex match
```

### Aggregation

```maqui
group every 1m / 5m / 1h / 1d    # time window
group by field1, field2            # field grouping
count() / sum(bytes) / avg(x) / max(x) / min(x)
humanSize(bytes)                   # format as 1.2GB
```

### Regex Extraction

```maqui
select re("pattern(.*)") as filter
select peek(field, re("pattern"), 1) as val
select subs(field, filter, template("\\1"))
```

### my.app Table Naming

```maqui
# Domain with @ must be backtick-quoted in Maqui (5-level name):
from my.app.`development@talion`.alertflow.tablename
from my.app.`admin@signalit`.back.logs

# Domain without @ (backticks optional):
from my.app.dsteam.fluentd
from my.synthesis.gitlab.rails.productionjson

# Web UI / Flow UI show 4-level names without domain embedded
```

---

## Common Tables

### Metadata Distribution & Lookup Management

| Table | Service | Purpose | Key Fields |
|-------|---------|---------|------------|
| `siem.logtrust.mason.free` | Mason Agent | Metadata file sync logs | logger, msg, eventdate, hostname, instance |
| `siem.logtrust.lomana.free` | Lomana | Lookup lifecycle logs | level, msg, logger, extra, eventdate |
| `system.internal.lookup` | System | Lookup table registry | domain, lookup, instance |
| `system.internal.aggrdef` | System | Casparables (aggregation definitions) | id, validUpto |

### Query Engine

| Table | Service | Purpose | Key Fields |
|-------|---------|---------|------------|
| `siem.logtrust.malote.free` | Malote | Query engine execution logs | message, instance, errorClass, errorMessage, errorTrace |
| `siem.logtrust.malote.gc` | Malote | GC events | message, instance, eventdate |
| `siem.logtrust.metamalote.free` | Metamalote | Query coordinator logs | coordinator_id, status, message |
| `system.delegated.internal.now` | System | Delegate health check | instance, eventdate |
| `system.delegated.internal.query` | System | Query tracking | user, language, currentDate, problem |
| `system.delegated.internal.manifest` | System | Service versions | name, key, value |
| `system.delegated.internal.jvm` | System | JVM properties | properties, command |
| `system.delegated.internal.table` | System | Table deployment | name, databaseinstance, client |
| `system.delegated.internal.tableFile` | System | Table files | client, tableName, path, eventdate |

### Load Balancing & Data Management

| Table | Service | Purpose | Key Fields |
|-------|---------|---------|------------|
| `siem.logtrust.batrasio.free` | Batrasio | Load balancer logs | message, instance, machine, eventdate |
| `siem.logtrust.batrasio.out` | Batrasio | Load balancer output | message, machine, eventdate |
| `siem.logtrust.barcenas.activity` | Barcenas | Data manager activity | datanode, message, eventdate |
| `siem.logtrust.barcenas.recounted` | Barcenas | Recount results (S3 size estimates) | sourceUuid, datanode, partition, trunkname, files, bytes |
| `siem.logtrust.flow.out` | Flow/Pilot | Ingestion pipeline logs | host, message, contextName, contextDomain |

### Data Ingestion

| Table | Service | Purpose | Key Fields |
|-------|---------|---------|------------|
| `syslog.alcohol.stats` | Alcohol | Ingestion statistics | client, kind, subkind, partialEventBytes, parameters, machine |
| `siem.logtrust.collector.counter` | Collector | Table ingestion counters | kind, object, bytes |

### System Monitoring

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `box.unix` / `box.win` | System metrics | machine, appName, message, application |
| `box.stat.unix.dstatLt1` | CPU/Memory stats | machine, cpuUsr, cpuSys, cpuSiq, cpuSte |
| `box.win_nxlog.security` | Windows security events | IpAddress, IpPort, EventID, LogonType, TargetUserName |
| `system.delegated.internal.indexing.licor.stat` | Index health | instance, indexpath, version, error |

---

## Mason Agent Health Check Query

Used by Dynatrace import (runs every 1 hour). Detects datanodes with sustained failures.

```maqui
from siem.logtrust.mason.free
where now() - 1h < eventdate < now()
where endswith(logger, 'Publisher'),
      msg -> 'failed=[agent:'
select re('.*failed=\\[agent:(.*)\\],.*') as Filter
select subs(msg, Filter, template("\\1"), msg) as Datanode
group every 10m by Datanode
select count() as count
where count > 10
group every 1h by Datanode
select count() as count2
where count2 > 3
```

**Logic:** Extracts datanode name from `failed=[agent:HOSTNAME]`, counts failures per 10-min window, alerts if >3 windows in the hour had >10 failures each (30+ minutes of sustained failures).

**Alert lag:** Dynatrace retains last imported value until next hourly cycle — wait 60+ min after Lodge fix before expecting Dynatrace to clear.

---

## Resources

**Web Portals:**
- EU: https://eu.devo.com/
- US: https://us.devo.com/
- APAC: https://apac.devo.com/
- US3: https://us3.devo.com/
- Telefonica: https://sasr.devo.com/
- Santander: https://dataplatform.san.devo.com/
- NCSC-Bahrain: https://portal.hawk.ncsc.gov.bh/

**NASS Client:**
- EU: https://nass-eu.devo.com/confDom
- US: https://nass-us.devo.com/confDom
- APAC: https://nass-ap.devo.com/confDom
- Santander: https://nass.san.devo.com/confDom

**Santander API:**
- Public API: https://apism.aacc.gs.corp (laptop/external queries)
- Internal API: https://api-internal.san.devo.com (VPC/AWS internal)
- OAuth token: `~/.devo/credentials.santander`

**Docs:**
- API: https://docs.devo.com/api/
- Maqui reference: https://docs.devo.com/maqui/
- Rehydration guide: https://devoinc.atlassian.net/wiki/spaces/CO/pages/3753017365/
