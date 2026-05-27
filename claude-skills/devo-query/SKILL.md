---
name: devo-query
description: Maqui query execution, Malote/Metamalote troubleshooting, and customer data investigation (my.app, my.synthesis). Use for all Devo platform data queries across 7 regions. Always source ~/.zshrc && before aliases in Claude Code.
argument-hint: "[region] [table] [domain]"
tags: [maqui, malote, metamalote, query, my.app, my.synthesis, customer-data]
---

## 🔴 CRITICAL: Always Start with Small Time Windows

**NEVER start a Maqui troubleshooting query with a large time window (e.g. `now()-2h`, `now()-24h`).**  
Large windows on busy tables load massive data and make Maqui very slow or unresponsive.

**Rule:** Always start with `now()-5m`. Expand only if needed, incrementally:
```
now()-5m  →  now()-15m  →  now()-30m  →  now()-1h  →  now()-6h  (only if justified)
```

```bash
# ✅ CORRECT — start small
source ~/.zshrc && maquieu "from siem.logtrust.asilo.activity where now()-5m <= eventdate < now() select * limit 20"

# ❌ WRONG — never start here
source ~/.zshrc && maquieu "from siem.logtrust.asilo.activity where now()-2h <= eventdate < now() select * limit 50"
```

---

## Maqui Function Reference & Query Library

> See: `~/.claude/skills/devo-query/maqui.md` — 97 helper function signatures + 75+ copy-paste LINQ queries organized by table. Read this file when you need a specific function name or a ready-to-run query for a given table.

---

## Quick Start (wrapper + aliases)

`.zshrc` is NOT loaded automatically in Claude Code. Always prefix with `source ~/.zshrc &&`:

```bash
source ~/.zshrc && maquieu "from system.internal.now select *"
source ~/.zshrc && maquius "from box.unix select machine limit 5"
source ~/.zshrc && maquiapac "from siem.logtrust.malote.free where now()-1h < eventdate < now() select * limit 10"
```

Short form alias: `source ~/.zshrc && maq eu "query"`

---

## Regions

| Alias | Endpoint | Region |
|-------|----------|--------|
| `maquieu` | 172.17.43.85:10100 | EU |
| `maquius` | 172.25.62.129:10100 | US |
| `maquius3` | 172.28.42.55:10100 | US3 |
| `maquiapac` | 10.7.10.237:10100 | APAC |
| `maquisant` | 172.27.25.107:10100 | Santander |
| `maquigcp` | 10.6.0.19:10100 | GCP Telefonica EU |
| `maquincsc` | 172.17.43.85:10100 | NCSC Bahrain (shares EU infra) |

---

## Query Patterns

### Basic syntax

```maqui
from <table>
where <filter_conditions>
select <fields>
group by <field>
```

### Time functions

```maqui
now() - 1h <= eventdate < now()    # Last hour (preferred form)
now() - 24h <= eventdate < now()   # Last 24h
"2026-04-30" <= eventdate < "2026-05-01"  # Absolute range
```

### Client filter rule — CRITICAL

**Always add `client` filter.** Without it, queries scan all clients and timeout (30+ sec).

- Internal Devo infrastructure: `where client = "self"`
- Customer data: `where client = "<domain>"` (e.g. `"teconnectivity"`, `"gitlab"`, `"dsteam"`)

**Performance:** 4–10x faster with filter. 7s first run → 0.024s cached (cache TTL 5 min).

### Key tables

| Table | Client | Purpose |
|-------|--------|---------|
| `siem.logtrust.malote.free` | `self` | Malote service logs |
| `siem.logtrust.malote.gc` | `self` | Malote GC events |
| `siem.logtrust.malote.query` | `self` | Malote query execution metrics |
| `siem.logtrust.metamalote.free` | `self` | Metamalote logs |
| `siem.logtrust.batrasio.free` | `self` | Batrasio logs |
| `siem.logtrust.lomana.free` | `self` | Lomana lookup lifecycle logs |
| `siem.logtrust.mason.free` | `self` | Mason agent distribution logs |
| `siem.logtrust.flow.out` | `self` | Alert flow/pilot logs |
| `syslog.alcohol.stats` | `self` | Ingestion statistics |
| `system.delegated.internal.table` | — | Table deployment registry |
| `system.delegated.internal.lookup` | — | Lookup deployment registry (ops/troubleshooting → `/devo-tools`) |
| `my.app.<domain>.*` | `<domain>` | Customer application tables |
| `my.synthesis.<domain>.*` | `<domain>` | Customer synthesis tables |
| `siem.logtrust.asilo.response` | `self` | Asilo command responses |

### Table deployment check (always run before querying)

```bash
# Verify table exists on datanodes
source ~/.zshrc && maquius "from system.delegated.internal.table where name = 'my.app.dsteam.fluentd' select name, databaseinstance(null) as datanode"

# Search by pattern
source ~/.zshrc && maquius "from system.delegated.internal.table where name ~ 'my.app.gitlab' select name, databaseinstance(null) as datanode"

# Find all tables for a domain
source ~/.zshrc && maquius "from system.delegated.internal.table where name ~ 'teconnectivity' select name, databaseinstance(null) as datanode"

# Lookup registry
source ~/.zshrc && maquisant "from system.delegated.internal.lookup where name -> 'my.synthesis' select name, databaseinstance(null) as datanode"
```

### Customer data (my.app / my.synthesis)

```bash
# my.app query
source ~/.zshrc && maquius 'from my.app.dsteam.fluentd where client = "dsteam" and now()-1h <= eventdate < now() select *'

# my.synthesis query
source ~/.zshrc && maquieu 'from my.synthesis.gitlab.rails.productionjson where client = "gitlab" and now()-6h <= eventdate < now() select * limit 10'

# Check Lomana is processing synthesis table
source ~/.zshrc && maquieu 'from siem.logtrust.lomana.free where client = "self" and lookup = "your_table_name" and msg -> "Lookup ready to use" order by eventdate desc limit 10'
```

---

## Helper Functions

Loaded via `~/.zshrc`. Always prefix with `source ~/.zshrc &&` in Claude Code.

```bash
# Health & connections
source ~/.zshrc && maqui_health_quick eu "self"
source ~/.zshrc && maqui_connections us "metamalote-1-pro-cloud-general-aws-us-east-1"
source ~/.zshrc && maqui_gc_check eu "datanode-1-pro-cloud-shared-aws-eu-west-1"
source ~/.zshrc && maqui_check_running_queries us

# Malote high-CPU domains
source ~/.zshrc && maqui_malote_high_cpu_domains eu 24 10000

# Ingestion monitoring
source ~/.zshrc && maqui_ingestion_technology us "self" 7
source ~/.zshrc && maqui_ingestion_by_collector eu "self" 1

# Cache management
source ~/.zshrc && maqui_cache_status
source ~/.zshrc && maqui_clear_cache        # Force fresh data
source ~/.zshrc && maqui_cache_disable      # Real-time monitoring mode
```

Modules: `~/Documents/Scripts/Maqui/modules/` (01-core, 02-health-checks, 03-query-data, 04-ingestion, 05-collectors, 06-data-management, 07-alerts)

---

## Malote / Metamalote Troubleshooting

### Architecture

```
Upstream (batrasio/relay) → Metamalote (port 10100) → Malote instances (i0–i7)

Malote instance ports:
  i0: 10101, 10102, 10901    i4: 10109, 10110, 10907
  i1: 10103, 10104, 10902    i5: 10111, 10112, 10908
  i2: 10105, 10106, 10905    i6: 10113, 10114, 10909
  i3: 10107, 10108, 10906    i7: 10115, 10116, 10910
```

### Connection explosion

**Symptoms:** 17K+ connections to single malote instance, 33K+ metamalote connections, 1500%+ CPU (Full GC), OOM every 1–2 hours. Root cause: high volume of small queries, metamalote not reusing connections. Each connection ~2MB heap; 17K × 2MB = 34GB >> 31GB limit.

```bash
# Connection counts per malote instance
for port in 10101 10103 10105 10107 10109 10111 10113 10115; do
    echo -n "Port $port: "
    ss -tnp | grep ":$port" | grep ESTAB | wc -l
done

# Metamalote total connections
lsof -p $(pgrep -f metamalote) 2>/dev/null | grep -c 'TCP.*ESTABLISHED'

# Source IPs
ss -tnp | grep ':10105' | grep ESTAB | awk '{print $5}' | cut -d: -f4 | sed 's/]$//' | sort | uniq -c | sort -rn
```

**Immediate fix:** `systemctl restart metamalote.service` (clears connections, not permanent)

**Healthy targets:** Metamalote < 5,000 total; per malote instance < 500.

### Heap exhaustion / Full GC

**Symptoms:** `GC: 31712M->31712M (0MB freed)`, CPU 1500%+, heap 99–100%.

```bash
jstat -gcutil $(pgrep -f 'malote.*i2') 1000 5
jmap -histo $(pgrep -f 'malote.*i2') | head -30
tail -1000 /var/log/malote/malote2.gc.log | grep 'Pause Full' | tail -20
grep 'OutOfMemoryError' /var/log/malote/malote.out.i2.log | tail -20

# Definition file count (82K+ files = 25–30GB heap when loaded)
find /etc/logtrust/malote/defs -type f -name '*.def' | wc -l
```

**JVM constraint:** Keep heap at 31GB max (`-Xmx31G`). JVM allocation doubles at 32GB boundary.

### Service management

```bash
systemctl status malote@i2.service / metamalote.service
systemctl restart malote@i2.service       # Single instance
systemctl restart malote.target           # All instances
systemctl restart metamalote.service
tail -100 /var/log/malote/malote.out.i2.log
journalctl -u malote@i2.service -n 100 --no-pager
```

### Key paths

```
Service files:    /etc/systemd/system/malote@.service, metamalote.service
Instance config:  /etc/logtrust/systemd/malote/HOSTNAME/i{0-7}.conf
Metamalote config:/etc/logtrust/metamalote-conf/metamalote.parameters
Definition files: /etc/logtrust/malote/defs/
Logs:             /var/log/malote/  /var/log/metamalote/
JVM (correct):    -Xms2G -Xmx31G -XX:+UseG1GC
Metamalote heap:  -Xms4G -Xmx31G  (do NOT set above 31G)
```

### Maqui queries for malote health

```bash
# GC activity
source ~/.zshrc && maquieu 'from siem.logtrust.malote.gc where client = "self" and now()-1h <= eventdate < now() select * limit 20'

# Errors
source ~/.zshrc && maquieu 'from siem.logtrust.malote.free where client = "self" and now()-1h <= eventdate < now() select * limit 20'

# High-CPU domains (last 24h, threshold 10000ms)
source ~/.zshrc && maquieu 'from siem.logtrust.malote.query where client = "self" and now()-24h <= eventdate < now() select ifthenelse(toktains(queryDomain,"@"),split(queryDomain,"@",1),queryDomain) as domain group every 1h by domain select sum(totalCPUMillisDelta) as cpu where cpu > 10000'

# Ingestion by technology (last 7 days)
source ~/.zshrc && maquieu 'from syslog.alcohol.stats where client = "self" and now()-7d <= eventdate < now() and kind = "technology" group every 1d by subkind select sum(partialEventBytes) as bytes'
```

---

## Related Skills

- `/devo-tools` — Mason/Lodge/Lomana metadata distribution, my.synthesis lifecycle, myapp-loader, **lookup troubleshooting (missing data, udlu, blank grid)**
- `/devo-database` — MySQL/Adolfo direct access (eu_pro/usa_pro/ap_pro/us3_pro/santander_eu)
- `/devo-infra` — Kubernetes, Ansible deployments, Malote JVM tuning
- `/devo-alert` — Alert management, Flow/Pilot/Cockpit
