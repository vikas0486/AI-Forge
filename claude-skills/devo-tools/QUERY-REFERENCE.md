# Devo Platform - Quick Query Reference

**Quick access to production queries**

Full documentation: `~/.claude/skills/devo-tools/README.md`

## Quick Categories

| Category | Queries | Use Case |
|----------|---------|----------|
| **Infrastructure Monitoring** | 30+ | Monitor Devo services (Mason, Malote, Metamalote, Batrasio, Lomana) |
| **Data Ingestion Monitoring** | 5+ | Track data flowing into platform (Alcohol, Collector) |
| **Data Storage & Retrieval** | 10+ | Query customer tables, check table deployment |
| **Performance & System** | 5+ | CPU, memory, GC pauses, indexes |
| **Affinity & Domain Mgmt** | 10+ | MySQL queries for trunk/domain configuration |
| **Advanced Data Management** | 5+ | Authenticated data deletion (use with caution) |

## Most Common Queries

### Check Mason Agent Failures (Dynatrace Alert)
```maqui
from siem.logtrust.mason.free
where now() - 1h < eventdate < now()
where endswith(logger, 'Publisher'), msg -> 'failed=[agent:'
select re('.*failed=\\[agent:(.*)\\],.*') as Filter
select subs(msg, Filter, template("\\1"), msg) as Datanode
group every 10m by Datanode
select count() as count where count > 10
group every 1h by Datanode
select count() as count2 where count2 > 3
```

### Check Ingestion by Domain
```maqui
from syslog.alcohol.stats
where now() - 12h < eventdate < now()
and client = "self"
and kind = "technology"
group every 10m
select count(), humanSize(sum(partialEventBytes))
```

### Check Metamalote Connections
```maqui
from box.unix
select machine, int(message) as connections
where now() - 1h <= eventdate < now()
where appName = "metamalote_connections"
group by machine
select max(int(message))
where max(int(message)) > 8000
```

### Check All Malotes Are Responding
```maqui
from system.delegated.internal.now
group by instance(databaseinfo())
pragma delegation.reaction.failed.connection.for: 0s
```

### Check Which Datanodes Have a Table Deployed
```maqui
select databaseinstance(null) as db
from system.delegated.internal.table
where name = "my.app.equifax.fraud.nctue"
group by db
```

### Query Customer Application Data
```maqui
select *
from my.app.`dsteam`.fluentd
where log_level = "ERROR"
where client = "dsteam"
where now() - 1h <= eventdate <= now()
limit 100
```

### Check Domain Affinity (MySQL)
```sql
SELECT t.name AS trunk_name, d.name AS domain
FROM affinity a, trunk t, domain d
WHERE a.trunk_id = t.id
  AND a.domain_id = d.id
  AND d.name LIKE '%customer%';
```

### Count Domains Per Trunk (MySQL)
```sql
SELECT trunk.name, COUNT(*) AS affinities
FROM affinity
JOIN trunk ON trunk_id = trunk.id
JOIN domain ON domain_id = domain.id
WHERE domain.status = 0
  AND trunk.name LIKE '%shared%'
  AND expiration_date IS NULL
GROUP BY trunk.name
ORDER BY affinities;
```

## Quick Access

### Run Maqui Query (Web UI)
1. Go to: https://eu.devo.com/#/search
2. Paste query in "Table" section
3. Adjust time range
4. Run

### Run MySQL Query
```bash
# EU
source ~/.zshrc && sql eu_pro

# APAC
source ~/.zshrc && sql ap_pro

# US
source ~/.zshrc && sql usa_pro
```

### Run via API (after loading credentials)
```bash
source ~/.zshrc  # loads maqui aliases
devo-region eu
source ~/.zshrc  # loads maqui aliases

devo_query "from siem.logtrust.mason.free where now() - 1h < eventdate < now()" 1
check_mason_failures 1
```

## Common Tables

**Infrastructure Monitoring Tables:**

| Table | Purpose |
|-------|---------|
| `siem.logtrust.mason.free` | Mason agent logs (file sync) |
| `siem.logtrust.malote.free` | Malote query engine logs |
| `siem.logtrust.metamalote.free` | Metamalote coordinator logs |
| `siem.logtrust.batrasio.free` | Batrasio load balancer logs |
| `siem.logtrust.lomana.free` | Lomana lookup manager logs |
| `siem.logtrust.barcenas.activity` | Barcenas data manager logs |
| `siem.logtrust.flow.out` | Flow/Pilot ingestion pipeline logs |
| `system.delegated.internal.*` | System internal state (delegates, tables, files) |
| `box.unix` / `box.win` | System metrics (connections, CPU, etc.) |
| `box.stat.unix.dstatLt1` | Detailed CPU/memory statistics |

**Data Ingestion Monitoring Tables:**

| Table | Purpose |
|-------|---------|
| `syslog.alcohol.stats` | Ingestion statistics by domain/technology |
| `siem.logtrust.collector.counter` | Table ingestion byte counters |

**Customer Data Tables:**

| Table Pattern | Purpose |
|---------------|---------|
| `my.app.<domain>.*` | Customer application logs/data |
| `my.synthesis.<domain>.*` | Customer synthesis/processed data |
| `box.win_nxlog.*` | Windows event logs |
| `box.unix` | Unix/Linux system logs |

**Metadata & Lookup Management:**

| Service | Table | Purpose |
|---------|-------|---------|
| **Mason Agent** | `siem.logtrust.mason.free` | Metadata file synchronization (downloads from S3) |
| **Lomana** | `siem.logtrust.lomana.free` | Lookup lifecycle management (creation, deployment) |

**Key Difference:**
- **Lomana** creates lookups and tells Mason to distribute them
- **Mason** ensures lookups (and other metadata) are synced across datanodes
- Lomana uses Mason as its distribution backend
- Mason replaces rsync for metadata distribution

## Query Syntax Quick Reference

**Time:**
```maqui
where now() - 1h < eventdate < now()           # Last hour
where "2024-02-01" <= eventdate < "2024-02-05" # Date range
```

**String Matching:**
```maqui
where msg -> "error"              # Contains (case-insensitive)
where msg ->> "ERROR"             # Contains (case-sensitive)
where startswith(msg, "Failed")   # Starts with
where endswith(msg, ".log")       # Ends with
```

**Aggregation:**
```maqui
group every 1m                    # Per minute
group every 1h                    # Per hour
group by field1, field2           # Group by fields
select count()                    # Count
select sum(bytes)                 # Sum
select humanSize(sum(bytes))      # Formatted size
```

## File Locations

- **Full Query Reference**: `~/.claude/skills/devo-tools/README.md`
- **Your Query Examples**:
  - `/Users/vikash.jaiswal/Documents/Scripts/Notepad-Maqui.sh`
  - `/Users/vikash.jaiswal/Documents/Scripts/Notepad-Queries.sh`
- **Credentials**: `~/.devo/credentials.*`
- **Quick Start**: `~/.devo/QUICK-START.md`

## Invoke Skill in Claude Code

```bash
/devo-tools
```

Shows full documentation with all query categories.
