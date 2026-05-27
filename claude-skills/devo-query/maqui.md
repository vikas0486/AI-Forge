# Maqui Reference — Copy-Paste Query Library

> Companion file to SKILL.md. All function signatures + ready-to-run LINQ queries.
> **EXECUTION:** Always `source ~/.zshrc && maquieu "query"` — the 7 `.zshrc` aliases are the ONLY valid execution method.
> **Notepad-Maqui.sh** is a user reference file — read it for query patterns/syntax only, never execute raw `command maqui` or per-node IPs from it.

---

## Terminal Output Format (Human-Readable)

When sharing Maqui output with the team, use this format:

```
vikash.jaiswal@Vikashs-MacBook Repository % maquieu '<query>'
Executing:
  <query>
With malote API
Columns (N):
  Column 0: eventdate/eventdate: timestamp
  Column 1: <field>/: <type>
  ...

<paste results here>
```

---

## PLEN-9169 — Required Casparable Blocking Files Investigation (2026-05-19)

All blocking grains for `required:*` casparables confirmed to be on **catawiki dedicated datanodes only**
(`datanode-1-pro-cloud-catawiki-aws-eu-west-1` and `datanode-2-pro-cloud-catawiki-aws-eu-west-1`).

Fix: Add `cloud,catawiki` delegation to `metamalote-general.yml` → MR in automation repo branch `CHG-10531/fix/add-catawiki-metamalote-delegation`.

### Query results

**1. domain.counter g15000 (2024-07-12)**
```
vikash.jaiswal@Vikashs-MacBook Repository % maquieu 'from system.delegated.internal.tableFile where "2024-07-12" <= eventdate < "2024-07-13" and tableName = "logtrust.aggr.required:siem.lt.scoja.domain.counter.g15000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all'
Executing:
  from system.delegated.internal.tableFile where "2024-07-12" <= eventdate < "2024-07-13" and tableName = "logtrust.aggr.required:siem.lt.scoja.domain.counter.g15000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all
With malote API
Columns (2):
  Column 0: eventdate/eventdate: timestamp
  Column 1: datanode/: str
2024-07-12 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10101
2024-07-12 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10103
2024-07-12 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10101
2024-07-12 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10103

Rows processed: 4
```

**2. domain.counter g300000 (2024-07-12)**
```
vikash.jaiswal@Vikashs-MacBook Repository % maquieu 'from system.delegated.internal.tableFile where "2024-07-12" <= eventdate < "2024-07-13" and tableName = "logtrust.aggr.required:siem.lt.scoja.domain.counter.g300000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all'
Executing:
  from system.delegated.internal.tableFile where "2024-07-12" <= eventdate < "2024-07-13" and tableName = "logtrust.aggr.required:siem.lt.scoja.domain.counter.g300000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all
With malote API
Columns (2):
  Column 0: eventdate/eventdate: timestamp
  Column 1: datanode/: str
2024-07-12 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10101
2024-07-12 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10103
2024-07-12 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10101
2024-07-12 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10103

Rows processed: 4
```

**3. me.counter g15000 (2024-07-13)**
```
vikash.jaiswal@Vikashs-MacBook Repository % maquieu 'from system.delegated.internal.tableFile where "2024-07-13" <= eventdate < "2024-07-14" and tableName = "logtrust.aggr.required:siem.lt.scoja.me.counter.g15000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all'
Executing:
  from system.delegated.internal.tableFile where "2024-07-13" <= eventdate < "2024-07-14" and tableName = "logtrust.aggr.required:siem.lt.scoja.me.counter.g15000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all
With malote API
Columns (2):
  Column 0: eventdate/eventdate: timestamp
  Column 1: datanode/: str
2024-07-13 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10101
2024-07-13 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10103
2024-07-13 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10101
2024-07-13 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10103

Rows processed: 4
```

**4. me.counter g300000 (2024-07-14)**
```
vikash.jaiswal@Vikashs-MacBook Repository % maquieu 'from system.delegated.internal.tableFile where "2024-07-14" <= eventdate < "2024-07-15" and tableName = "logtrust.aggr.required:siem.lt.scoja.me.counter.g300000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all'
Executing:
  from system.delegated.internal.tableFile where "2024-07-14" <= eventdate < "2024-07-15" and tableName = "logtrust.aggr.required:siem.lt.scoja.me.counter.g300000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all
With malote API
Columns (2):
  Column 0: eventdate/eventdate: timestamp
  Column 1: datanode/: str
2024-07-14 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10101
2024-07-14 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10103
2024-07-14 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10101
2024-07-14 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10103

Rows processed: 4
```

**5. collector.counter g15000 (2024-07-15)**
```
vikash.jaiswal@Vikashs-MacBook Repository % maquieu 'from system.delegated.internal.tableFile where "2024-07-15" <= eventdate < "2024-07-16" and tableName = "logtrust.aggr.required:siem.logtrust.collector.counter.g15000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all'
Executing:
  from system.delegated.internal.tableFile where "2024-07-15" <= eventdate < "2024-07-16" and tableName = "logtrust.aggr.required:siem.logtrust.collector.counter.g15000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all
With malote API
Columns (2):
  Column 0: eventdate/eventdate: timestamp
  Column 1: datanode/: str
2024-07-15 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10101
2024-07-15 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10103
2024-07-15 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10101
2024-07-15 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10103

Rows processed: 4
```

**6. collector.counter g300000 (2024-07-17)**
```
vikash.jaiswal@Vikashs-MacBook Repository % maquieu 'from system.delegated.internal.tableFile where "2024-07-17" <= eventdate < "2024-07-18" and tableName = "logtrust.aggr.required:siem.logtrust.collector.counter.g300000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all'
Executing:
  from system.delegated.internal.tableFile where "2024-07-17" <= eventdate < "2024-07-18" and tableName = "logtrust.aggr.required:siem.logtrust.collector.counter.g300000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all
With malote API
Columns (2):
  Column 0: eventdate/eventdate: timestamp
  Column 1: datanode/: str
2024-07-17 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10101
2024-07-17 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10103
2024-07-17 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10101
2024-07-17 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10103

Rows processed: 4
```

**7. domain.counter g3600000 (2024-09-17)**
```
vikash.jaiswal@Vikashs-MacBook Repository % maquieu 'from system.delegated.internal.tableFile where "2024-09-01" <= eventdate < "2024-10-01" and tableName = "logtrust.aggr.required:siem.lt.scoja.domain.counter.g3600000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all'
Executing:
  from system.delegated.internal.tableFile where "2024-09-01" <= eventdate < "2024-10-01" and tableName = "logtrust.aggr.required:siem.lt.scoja.domain.counter.g3600000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all
With malote API
Columns (2):
  Column 0: eventdate/eventdate: timestamp
  Column 1: datanode/: str
2024-09-01 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10101
2024-09-01 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10103
2024-09-01 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10101
2024-09-01 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10103

Rows processed: 4
```

**8. collector.counter g3600000 (2024-11-05)**
```
vikash.jaiswal@Vikashs-MacBook Repository % maquieu 'from system.delegated.internal.tableFile where "2024-11-01" <= eventdate < "2024-12-01" and tableName = "logtrust.aggr.required:siem.logtrust.collector.counter.g3600000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all'
Executing:
  from system.delegated.internal.tableFile where "2024-11-01" <= eventdate < "2024-12-01" and tableName = "logtrust.aggr.required:siem.logtrust.collector.counter.g3600000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all
With malote API
Columns (2):
  Column 0: eventdate/eventdate: timestamp
  Column 1: datanode/: str
2024-11-01 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10101
2024-11-01 05:30:00.0 datanode-1-pro-cloud-catawiki-aws-eu-west-1:10103
2024-11-01 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10101
2024-11-01 05:30:00.0 datanode-2-pro-cloud-catawiki-aws-eu-west-1:10103

Rows processed: 4
```

**9. me.counter g3600000 (2024-12-02)**
```
vikash.jaiswal@Vikashs-MacBook Repository % maquieu 'from system.delegated.internal.tableFile where "2024-12-01" <= eventdate < "2025-01-01" and tableName = "logtrust.aggr.required:siem.lt.scoja.me.counter.g3600000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all'
Executing:
  from system.delegated.internal.tableFile where "2024-12-01" <= eventdate < "2025-01-01" and tableName = "logtrust.aggr.required:siem.lt.scoja.me.counter.g3600000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all
With malote API
Columns (2):
  Column 0: eventdate/eventdate: timestamp
  Column 1: datanode/: str

Rows processed: 0
```

**10. collectorConsumptions g3600000 (2024-09-19)**
```
vikash.jaiswal@Vikashs-MacBook Repository % maquieu 'from system.delegated.internal.tableFile where "2024-09-01" <= eventdate < "2024-10-01" and tableName = "logtrust.aggr.required:collectorConsumptions.g3600000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all'
Executing:
  from system.delegated.internal.tableFile where "2024-09-01" <= eventdate < "2024-10-01" and tableName = "logtrust.aggr.required:collectorConsumptions.g3600000" select instance(databaseinfo()) as datanode group every 1h by datanode pragma data.migration.all
With malote API
Columns (2):
  Column 0: eventdate/eventdate: timestamp
  Column 1: datanode/: str

Rows processed: 0
```

---

## Critical Rules Before Running Any Query

| Rule | Detail |
|------|--------|
| **client filter** | ALWAYS add `where client = "self"` or `where client = "domain"` — without it, query scans all clients and times out (30+ sec) |
| **syslog.alcohol.stats** | In Santander, no `client` column — use `subkind` or `machine` to filter instead |
| **group every 1d** | NEVER write `group every 1d by eventdate` — `eventdate` is auto-generated; use `group every 1d by otherfield` or `group every 1d select ...` |
| **time range syntax** | `now() - 1h <= eventdate < now()` (preferred). Absolute: `"2026-05-01" <= eventdate < "2026-05-02"` |
| **shell quoting** | Double-quote strings in LINQ inside single-quoted bash: `maquieu 'from ... where client = "self" ...'` |

---

## Aliases (Always via `source ~/.zshrc &&`)

```bash
source ~/.zshrc && maquieu "query"        # EU
source ~/.zshrc && maquius "query"        # US
source ~/.zshrc && maquius3 "query"       # US3
source ~/.zshrc && maquiapac "query"      # APAC
source ~/.zshrc && maquisant "query"      # Santander
source ~/.zshrc && maquigcp "query"       # GCP Telefonica EU
source ~/.zshrc && maquincsc "query"      # NCSC Bahrain (same infra as EU)

# Long form
source ~/.zshrc && maq eu "query"
source ~/.zshrc && maq sant "query"
```

**Endpoints (primary metamalote-1):**
| Region | IP:Port |
|--------|---------|
| eu | 172.17.43.85:10100 |
| us | 172.25.62.129:10100 |
| us3 | 172.28.42.55:10100 |
| apac | 10.7.10.237:10100 |
| sant | 172.27.25.107:10100 |
| gcp | 10.6.0.19:10100 |
| ncsc | 172.17.43.85:10100 (same as EU) |

---

## Function Reference

### Core / Cache (01-core.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `maqui` | `maqui <region> '<query>' [cache]` | Core query executor with auto-failover and caching |
| `maqui_failover` | `maqui_failover <region> '<query>'` | Try primary → secondary → tertiary → DNS |
| `maqui_regions` | `maqui_regions` | List available regions |
| `maqui_show_endpoints` | `maqui_show_endpoints` | Show all configured IPs |
| `maqui_cache_status` | `maqui_cache_status` | Show cache stats and TTL |
| `maqui_clear_cache` | `maqui_clear_cache` | Flush query cache |
| `maqui_cache_disable` | `maqui_cache_disable` | Disable cache for session |
| `maqui_cache_enable` | `maqui_cache_enable` | Re-enable cache |
| `maqui_benchmark` | `maqui_benchmark <region> '<query>' [n]` | Time query execution N times |

### Health Checks (02-health-checks.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `maqui_health_quick` | `maqui_health_quick [region] <client>` | 15-min malote error count |
| `maqui_malote_errors` | `maqui_malote_errors [region] <datanode>` | Malote errors by datanode (1h) |
| `maqui_malote_restarts` | `maqui_malote_restarts [region] [days] [pattern]` | Restart history |
| `maqui_malote_versions` | `maqui_malote_versions [region]` | Malote version across cluster |
| `maqui_gc_check` | `maqui_gc_check [region] <datanode>` | GC activity count (1h) |
| `maqui_gc_full` | `maqui_gc_full [region] <datanode>` | Full GC events (1h) |
| `maqui_gc_pauses` | `maqui_gc_pauses [region] [threshold_ms] [client]` | Long GC pauses (default >350s per 5min) |
| `maqui_connections` | `maqui_connections [region] <datanode>` | Max metamalote connections for datanode |
| `maqui_connections_all` | `maqui_connections_all [region] [client]` | Connections across all datanodes |
| `maqui_connections_threshold` | `maqui_connections_threshold [region] [threshold] [client]` | Alert when connections > N |
| `maqui_check_delegates` | `maqui_check_delegates [region]` | Check all delegates responding |
| `maqui_delegate_delay` | `maqui_delegate_delay [region]` | Clock sync check across delegates |
| `maqui_memory_limit` | `maqui_memory_limit [region]` | JVM memory limit per instance |
| `maqui_test_maxmind` | `maqui_test_maxmind [region]` | GeoIP country/region/city test |
| `maqui_corrupted_indexes` | `maqui_corrupted_indexes [region] [days]` | Index corruption last N days |
| `maqui_corrupted_indexes_range` | `maqui_corrupted_indexes_range <region> <start> <end>` | Index corruption in date range |
| `maqui_open_files_check` | `maqui_open_files_check [region] <client>` | "Too many open files" errors |
| `maqui_box_errors` | `maqui_box_errors [region] [days]` | box.unix system errors |
| `maqui_daily_output` | `maqui_daily_output <region> <date> <machine>` | Daily output for specific machine |
| `maqui_dropped_datanodes` | `maqui_dropped_datanodes [region] [start_date] [client]` | Dropped datanode alerts |
| `maqui_parallel_check` | `maqui_parallel_check <region> <dn1> <dn2> ...` | Parallel GC+connections check |
| `maqui_batrasio_targets` | `maqui_batrasio_targets [region] <start> <end> [client]` | No usable targets errors |
| `maqui_batrasio_stalled` | `maqui_batrasio_stalled [region] [client]` | Stalled domains per hour |
| `maqui_batrasio_conn_fail` | `maqui_batrasio_conn_fail [region] [machine] [client]` | Connection failures >3/min |
| `maqui_malote_high_cpu_domains` | `maqui_malote_high_cpu_domains [region] [hours] [threshold] [client]` | High-CPU domains on shared infra |

### Query Data (03-query-data.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `maqui_table_deployment` | `maqui_table_deployment [region] <table>` | Which datanodes host this table |
| `maqui_table_exists` | `maqui_table_exists [region] <pattern>` | Tables matching pattern |
| `maqui_metamafia_check` | `maqui_metamafia_check [region] <pattern>` | Parser (metamafia) check |
| `maqui_table_data_check` | `maqui_table_data_check [region] <client> <table> [hours]` | Record count in table |
| `maqui_customer_data` | `maqui_customer_data [region] <table> <client> [hours]` | Sample customer data |
| `maqui_synthesis_data` | `maqui_synthesis_data [region] <table> <client> [hours]` | Synthesis data hourly |
| `maqui_count_table_data` | `maqui_count_table_data [region] <table> <client> <start> <end>` | Count in date range |
| `maqui_list_tables` | `maqui_list_tables [region] [pattern]` | List tables in cluster |
| `maqui_check_table_files` | `maqui_check_table_files [region] <client> <table>` | Table file locations and sizes |
| `maqui_count_tables_per_datanode` | `maqui_count_tables_per_datanode [region]` | Table count per datanode |
| `maqui_check_table_file_integrity` | `maqui_check_table_file_integrity [region] <client> <table> [days]` | Find missing table files |
| `maqui_find_orphaned_table_files` | `maqui_find_orphaned_table_files [region] <client>` | Files without a table definition |
| `maqui_list_metamafias` | `maqui_list_metamafias [region]` | All system.metamafia.* tables |
| `maqui_check_metamafia_for_domain` | `maqui_check_metamafia_for_domain [region] <domain>` | Parsers for a domain |
| `maqui_lookup_availability` | `maqui_lookup_availability [region] <domain> <lookup>` | Datanodes missing a lookup |
| `maqui_lookup_details` | `maqui_lookup_details [region] <lookup> <domain>` | Lookup content details |
| `maqui_lomana_errors` | `maqui_lomana_errors [region]` | Lomana ERROR messages |
| `maqui_lomana_processing` | `maqui_lomana_processing [region] <start> [end]` | Lomana Lucifer processing |
| `maqui_lomana_config_errors` | `maqui_lomana_config_errors [region] [hours]` | Lomana config errors |
| `maqui_check_running_queries` | `maqui_check_running_queries [region] [client]` | Currently running queries |
| `maqui_check_query_history` | `maqui_check_query_history [region] [hours] [client]` | Query history |
| `maqui_check_slow_queries` | `maqui_check_slow_queries [region] [hours] [min_ms]` | Slow queries >N ms |
| `maqui_analyze_query_performance` | `maqui_analyze_query_performance [region] [hours]` | Query perf by user |
| `maqui_find_queries_with_errors` | `maqui_find_queries_with_errors [region] [hours]` | Queries that errored |
| `maqui_check_reinjection_status` | `maqui_check_reinjection_status [region]` | Overdue reinjections summary |
| `maqui_list_overdue_reinjections` | `maqui_list_overdue_reinjections [region] [min]` | List reinjections delayed >N min |
| `maqui_casperables_check` | `maqui_casperables_check [region]` | Active casperable aggregations |
| `maqui_running_queries` | `maqui_running_queries [region] <pattern> [hours]` | Queries matching language pattern |
| `maqui_command_history` | `maqui_command_history [region] <machine> [days]` | Shell command history on machine |
| `maqui_count_lookups_local` | `maqui_count_lookups_local [region]` | Count lookups on local instance |

### Ingestion (04-ingestion.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `maqui_ingestion_domain` | `maqui_ingestion_domain [region] <client> <subkind>` | Ingestion 12h 10-min buckets |
| `maqui_ingestion_technology` | `maqui_ingestion_technology [region] <pattern> [days] [client]` | Ingestion daily by technology |
| `maqui_table_ingestion` | `maqui_table_ingestion [region] <table_pattern>` | Bytes written to table hourly |
| `maqui_ingestion_parameters` | `maqui_ingestion_parameters [region] <subkind> <params> [kind] <date>` | Ingestion with specific params |
| `maqui_ingestion_by_collector` | `maqui_ingestion_by_collector [region] [days] [client]` | Bytes per collector per hour |
| `maqui_collector_stats` | `maqui_collector_stats [region] <client>` | 24h ingestion breakdown by subkind |

### Collectors (05-collectors.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `maqui_collector_errors` | `maqui_collector_errors [region] <client> [hours]` | Collector errors from syslog.alcohol.stats |

### Data Management (06-data-management.sh) ⚠️ Destructive

| Function | Signature | Description |
|----------|-----------|-------------|
| `maqui_casperable_view` | `maqui_casperable_view [region] <aggr> <client> <start> <end>` | View casperable data |
| `maqui_list_files_to_delete` | `maqui_list_files_to_delete [region] <client> <start> <end> [tables]` | DRY RUN: list files |
| `maqui_count_data_before_deletion` | `maqui_count_data_before_deletion [region] <client> <start> <end>` | DRY RUN: count/size |
| `maqui_list_trash` | `maqui_list_trash [region] <client> [days]` | List trashed files |
| `maqui_count_trash_by_client` | `maqui_count_trash_by_client [region] [days]` | Trash by client |
| `maqui_check_trash_retention` | `maqui_check_trash_retention [region] <client>` | Trash retention per datanode |
| `maqui_find_old_trash` | `maqui_find_old_trash [region] [retention_days]` | Trash older than N days |
| `maqui_audit_log_view` | `maqui_audit_log_view [lines]` | View destruction audit log |
| `maqui_audit_log_search` | `maqui_audit_log_search <term>` | Search audit log |

### Alerts / Flow (07-alerts.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `maqui_flow_errors` | `maqui_flow_errors [region] [hours] [client]` | Flow unit execution errors |
| `maqui_pilot_errors` | `maqui_pilot_errors <region> <host_pattern> [hours] [client]` | Pilot errors by host |
| `maqui_flow_status` | `maqui_flow_status [region] [hours] [client]` | Event count per flow host |
| `maqui_alert_volume` | `maqui_alert_volume [region] [hours] [client]` | Alert errors by context |
| `maqui_pilot_status` | `maqui_pilot_status [region] [hours] [client]` | Pilot host activity |
| `maqui_alert_error_logs` | `maqui_alert_error_logs [region] [hours] [client]` | Anti-flooding logs |
| `maqui_alert_flood_check` | `maqui_alert_flood_check [region] [hours] [client]` | Flooding/throttle events |
| `maqui_alert_error_domain` | `maqui_alert_error_domain <region> <domain> [hours]` | Alert errors for customer |
| `maqui_backend_info_logs` | `maqui_backend_info_logs [region] [hours] [client]` | Backend service events |
| `maqui_backend_errors` | `maqui_backend_errors [region] [hours] [client]` | Backend ERROR/WARN |
| `maqui_pilot_error_table` | `maqui_pilot_error_table [region] [hours] [client]` | Pilot-specific errors |
| `maqui_alert_delivery_status` | `maqui_alert_delivery_status [region] [hours] [client]` | Alert delivery failures |
| `maqui_alert_antiflooding_active` | `maqui_alert_antiflooding_active <region> <domain> [hours]` | Anti-flooding active events |

---

## Copy-Paste Queries by Table

### siem.logtrust.malote.free — Malote Service Logs

```linq
# Quick health check (15 min)
from siem.logtrust.malote.free
where client = "self" and now() - 15m < eventdate < now()
where errorMessage -> "error" or errorMessage -> "timeout"
group by client select count() as errors limit 100
pragma query.timeout: 0

# Errors by datanode (1h)
from siem.logtrust.malote.free
where instance -> "datanode-2-pro-cloud-shared-aws-eu-west-1" and now() - 1h < eventdate < now()
where errorMessage -> "error" or errorClass -> "Exception"
select eventdate, errorMessage, errorClass limit 50

# Restart history (7 days)
from siem.logtrust.malote.free
where client = "self" and now() - 7d <= eventdate < now()
and toktains(message, "Malote started")
select eventdate, instance, message order by eventdate desc

# Too many open files
from siem.logtrust.malote.free
where client = "self" and now() - 1d <= eventdate < now()
where toktains(errorTrace, "Too many open files")
select *

# Dropped datanodes
from siem.logtrust.malote.free
where client = "self" and now() - 1d <= eventdate
where errorMessage -> "Dropped" or errorMessage -> "datanode"
select eventdate, instance, errorMessage, errorTrace limit 50
```

### siem.logtrust.malote.query — Query CPU Metrics

```linq
# High CPU domains on shared infra (24h, >10000ms) ⭐
from siem.logtrust.malote.query
where client = "self" and now() - 24h <= eventdate < now()
where toktains(machine, "shared")
select ifthenelse(toktains(queryDomain, "@"), split(queryDomain, "@", 1), queryDomain) as dominio
where isnotnull(dominio)
group every 1h by dominio
select sum(totalCPUMillisDelta) as CPU
where CPU > 10000

# Query performance by domain (1h)
from siem.logtrust.malote.query
where client = "self" and now() - 1h < eventdate < now()
select queryDomain, count() as query_count,
       avg(totalCPUMillisDelta) as avg_cpu, sum(totalCPUMillisDelta) as total_cpu
group by queryDomain order by total_cpu desc
```

### siem.logtrust.malote.gc — Garbage Collection

```linq
# GC activity count (1h, specific datanode)
from siem.logtrust.malote.gc
where instance -> "datanode-2-pro-cloud-shared-aws-eu-west-1" and now() - 1h < eventdate < now()
where message -> "Pause"
group by instance select count() as gc_count
pragma query.timeout: 0

# Full GC events
from siem.logtrust.malote.gc
where client = "self" and now() - 1h <= eventdate < now()
where instance -> "datanode-2-pro-cloud-shared-aws-eu-west-1" and message ~ "Full"
select eventdate, message

# GC by datanode (1h overview)
from siem.logtrust.malote.gc
where client = "self" and now() - 1h < eventdate < now()
group by instance
select instance, count() as gc_events,
       avg(float(subs(message, re("([0-9.]+)ms"), template("\\1")))) as avg_pause_ms
```

### box.unix — System Metrics & Connections

```linq
# Metamalote connections for specific datanode
from box.unix
where appName = "metamalote_connections"
and machine -> "datanode-2-pro-cloud-shared-aws-eu-west-1"
and now() - 1h <= eventdate < now()
select machine, int(message) as connections
group by machine select max(int(message))

# All metamalote connections (healthy: <5000 total)
from box.unix
where client = "self" and appName = "metamalote_connections"
and now() - 1h <= eventdate < now()
select machine, int(message) as connections
group by machine select max(int(message))

# Connection threshold alert (>8000)
from box.unix
where client = "self" and appName = "metamalote_connections"
and now() - 1h <= eventdate < now()
select machine, int(message) as connections
group by machine select max(int(message))
where max(int(message)) > 8000
```

### syslog.alcohol.stats — Ingestion Statistics

```linq
# Ingestion by technology (7 days, human readable) ⭐
from syslog.alcohol.stats
where client = "self" and now() - 7d <= eventdate < now()
and kind = "technology" and subkind ~ "pattern"
group every 1d by subkind
select sum(partialEventBytes) as bytes, humanSize(bytes, false) as humanbytes

# Ingestion by domain (12h, 10-min buckets)
from syslog.alcohol.stats
where now() - 12h < eventdate < now()
and client = "customer-domain" and kind = "technology" and subkind = "technology-name"
group every 10m
select count(), humanSize(sum(partialEventBytes))

# Santander — no client column, use subkind ⚠️
from syslog.alcohol.stats
where subkind = "pre_gtb_bam" and now() - 30d <= eventdate < now()
group every 1d
select humanSize(sum(partialEventBytes)) as bytes

# Ingestion by collector (hourly)
from syslog.alcohol.stats
where client = "self" and now() - 1d < eventdate < now()
group every 1h by machine
select humanSize(sum(partialEventBytes)) as bytes_per_hour

# Collector stats 24h breakdown
from syslog.alcohol.stats
where client = "customer-domain" and now() - 24h < eventdate < now()
group by subkind
select subkind, count() as events, humanSize(sum(partialEventBytes)) as total_bytes
```

### siem.logtrust.batrasio.free — Batrasio Errors

```linq
# No usable targets
from siem.logtrust.batrasio.free
where client = "self"
and "2026-05-01" <= eventdate < "2026-05-02"
and message ~ "No usable targets"
select *

# Stalled domains hourly
from siem.logtrust.batrasio.free
where client = "self" and message ->> "was stalled"
select peek(message, re("domain=([^,]+)"), 1) as domain_aux
select ifthenelse(toktains(domain_aux, "@"), split(domain_aux, "@", 1), domain_aux) as domain
where isnotnull(domain), not eq(domain, "null")
group every 1h by domain select count() as count
```

### system.delegated.internal.table — Table Discovery

```linq
# Where is this table deployed?
select databaseinstance(null) as db
from system.delegated.internal.table
where name = "my.app.dsteam.fluentd"
group by db

# Find tables by pattern
select name, databaseinstance(null) as datanode
from system.delegated.internal.table
where weakhas(name, "gitlab")
group by name, datanode order by name

# Tables for a domain
select name, databaseinstance(null) as datanode
from system.delegated.internal.table
where weakhas(name, "teconnectivity")
group by name, datanode order by name

# Count tables per datanode
select databaseinstance(null) as datanode, count() as table_count
from system.delegated.internal.table
group by datanode order by table_count desc
```

### system.delegated.internal.lookup — Lookup Registry

```linq
# Which datanodes are missing this lookup?
from system.delegated.internal.now
select (instance(databaseinfo()), port(databaseinfo())) as malote
where not malote in (
    from system.delegated.internal.lookup
    where domain = "customer-domain" and lookup = "LookupName"
    select (instance(databaseinfo()), port(databaseinfo()))
)
group by malote

# Count all lookups
from system.internal.lookup
group select count()
```

### system.delegated.internal.query — Running Queries

```linq
# Currently running queries
from system.delegated.internal.query
where state = "RUNNING"
select user, language, currentDate, instance(databaseinfo())
limit 50

# Slow queries (>10s) last 24h
from system.delegated.internal.query
where now() - 24h < currentDate < now()
and millisecond(endDate - currentDate) > 10000
select user, millisecond(endDate - currentDate) as duration_ms, language, currentDate
order by duration_ms desc limit 50

# Queries with errors
from system.delegated.internal.query
where now() - 24h < currentDate < now()
and problem is not null
select user, problem, language, currentDate
order by currentDate desc limit 50
```

### system.delegated.internal.now — Cluster Health

```linq
# All delegates responding?
from system.delegated.internal.now
group by instance(databaseinfo())
pragma delegation.reaction.failed.connection.for: 0s

# Clock sync across delegates
from system.delegated.internal.now
group by eventdate - now() as delay, instance(databaseinfo())
pragma delegation.reaction.failed.connection.for: 0s
```

### system.delegated.internal.manifest — Versions

```linq
# Malote version across cluster
select instance(databaseinfo()) as datanode, key, value
from system.delegated.internal.manifest
where name = "malote"
and key in {"Build-Date", "Implementation-Version"}
group by datanode, key, value order by datanode
```

### system.delegated.internal.indexing.licor.stat — Corrupt Indexes

```linq
# Corrupted indexes (last 7 days)
where now() - 7d <= eventdate < now()
from system.delegated.internal.indexing.licor.stat
select instance(databaseinfo()) as i, indexpath, version, error
where error != null
group every 1d by i, indexpath

# Corrupted indexes (date range)
where "2026-05-01" <= eventdate < "2026-05-14"
from system.delegated.internal.indexing.licor.stat
select instance(databaseinfo()) as i, indexpath, version, error
where error != null
group every 1d by i, indexpath
```

### my.app.* — Customer Application Data

```linq
# Recent customer data (always include client filter!)
from my.app.dsteam.fluentd
where client = "dsteam" and now() - 1h < eventdate < now()
limit 10

# Count records in range
from my.app.tablename
where client = "customer-domain"
and "2026-04-01" <= eventdate < "2026-05-01"
select count() as total_records

# Sample with all fields
from my.app.tablename
where client = "customer-domain" and now() - 6h < eventdate < now()
select * limit 100
```

### Cross-Domain Injection — Diagnosis Queries

**Reference case:** ISM-16741 — `slith@gable` → `gsoc@gable` injection silent failure (APAC)

**Key insight:** Always query BOTH source and target tables with identical time windows and compare counts.
A gap in the target with healthy source = injection broken, not a data generation problem.

```bash
# Step 1 — Check target table (injected data): does data stop at a specific date?
source ~/.zshrc && maquiapac "from my.app.\`gsoc@gable\`.slith.alert where client = \"gsoc@gable\" where now() - 30d <= eventdate group every 1d select count() as records, eventdate"

# Step 2 — Check source table (alert generation): is source healthy continuously?
source ~/.zshrc && maquiapac "from siem.logtrust.alert.info where client = \"slith@gable\" where now() - 21d <= eventdate group every 1d select count() as daily_alerts, eventdate"

# INTERPRETATION:
# - Source healthy + target dead after date X → injection broke at X
# - Source gap + target gap → data generation issue, not injection
# - Counts match before cutoff → injection was faithfully copying data

# Step 3 — Extract actual injection query from Malote (look for hardcoded le() ceiling)
source ~/.zshrc && maquiapac "from siem.logtrust.malote.query where client = \"self\" where now() - 24h <= eventdate where has(raw, \"reinjection\") where has(raw, \"slith\") select eventdate, raw limit 5"

# Step 4 — Check Batrasio for revoked cert blocking writes
source ~/.zshrc && maquiapac "from siem.logtrust.batrasio.free where client = \"self\" where now() - 7d <= eventdate where has(message, \"Revoked\") or has(message, \"revoked\") select eventdate, message, instance limit 20"

# Step 5 — Check injection metadata (no errors despite broken injection)
source ~/.zshrc && maquiapac "from my.synthesis.laszlo.injection where eq(queryDomain,\"slith@gable\") select eventdate, queryDomain, status, errorMessage, errorCode order by eventdate desc limit 20"
```

**Two silent failure modes (both show `alive`, zero errors):**

| Mode | Symptom | Fix |
|------|---------|-----|
| Hardcoded `le(timestamp(N))` upper bound | Target stops at a specific date/time matching the timestamp | Delete + recreate injection with rolling window `ge(now() - 1h, eventdate)` |
| Revoked relay certificate on Batrasio | TLS AUTH rejections in `siem.logtrust.batrasio.free` for `CN=<relay>` | Re-issue cert under regional CA, deploy to relay host |

**Hardcoded ceiling example (broken):**
```
where le(timestamp(1778068388901), eventdate)   ← static May 6 2026 — matches nothing after
```
**Fixed rolling window:**
```
where ge(now() - 1h, eventdate)   ← always matches last hour
```

**Note on `my.app.<domain>.<name>` table syntax:** backtick-escape domains containing `@`:
```bash
from my.app.`gsoc@gable`.slith.alert where client = "gsoc@gable"
```

---

### my.synthesis.* — Customer Synthesis Data

```linq
# Synthesis data (hourly aggregation)
select * from my.synthesis.tablename
where client = "customer-domain"
and now() - 6h <= eventdate <= now()
group every 1h

# Recent synthesis records
from my.synthesis.gitlab.rails.productionjson
where client = "gitlab" and now() - 6h <= eventdate < now()
select * limit 10
```

### siem.logtrust.flow.out — Flow/Pilot Errors

```linq
# Flow execution errors (1h)
from siem.logtrust.flow.out
where client = "self" and now() - 1h < eventdate < now()
where message -> "Unexpected error executing unit. Re-executing until stop is requested"
group every 1m by host, contextName
select host, contextName, count() as error_count where error_count > 0

# Alert volume by context (24h)
from siem.logtrust.flow.out
where client = "self" and now() - 24h < eventdate < now()
where message -> "error" or message -> "ERROR"
group every 1h by contextName
select contextName, count() as error_count order by error_count desc
```

### siem.logtrust.alert.error — Alert Anti-flooding

```linq
# Anti-flooding logs (24h)
from siem.logtrust.alert.error
where client = "self" and now() - 24h < eventdate < now()
group every 1h by level, message
select level, message, count() as occurrences
order by occurrences desc

# Flooding events
from siem.logtrust.alert.error
where client = "self" and now() - 24h < eventdate < now()
and (weakhas(message, "flood") or weakhas(message, "limit") or weakhas(message, "throttle"))
group every 10m by message
select eventdate, message, count() as occurrences order by eventdate desc

# Customer-specific alert errors
from siem.logtrust.alert.error
where client = "customer-domain" and now() - 24h < eventdate < now()
group every 1h
select count() as error_count, humanSize(sum(bytes)) as data_volume
where error_count > 0
```

### siem.logtrust.lomana.free — Lomana (Lookup Service)

```linq
# Lomana errors
from siem.logtrust.lomana.free
where level = "ERROR"
select splitre(extra, re("\\n.*$"), 0) as extraSummary
group every 10m by extraSummary, msg, logger every 10m
select count(level) as count

# Lookup ready events (check synthesis table ready)
from siem.logtrust.lomana.free
where client = "self" and lookup = "your_lookup_name"
and msg -> "Lookup ready to use"
order by eventdate desc limit 10
```

---

## Common Patterns

### Ingestion trend with human-readable sizes
```linq
from syslog.alcohol.stats
where client = "self" and now() - 30d <= eventdate < now()
and kind = "technology" and subkind ~ "domain-pattern"
group every 1d
select humanSize(sum(partialEventBytes)) as daily_bytes
```

### Table deployment check before querying
```bash
# Always verify table exists on datanodes before running queries against it
source ~/.zshrc && maquius 'from system.delegated.internal.table where name = "my.app.dsteam.fluentd" select name, databaseinstance(null) as datanode'
```

### Reinjection backlog
```linq
from system.delegated.internal.query
where user ~ "meta[tT]able"
select pragmavalue(language, problem, "comment.id") as reinjection
group by reinjection
select min(currentDate) as date, now() - date as delay
where delay > 5m
group select count(), duration(max(millisecond(delay)))
pragma proc.vault.name: "high"
```

### File data for DRY RUN before deletion
```linq
select count() as total_files, humanSize(sum(filesize(file))) as total_size
from system.delegated.internal.tableFile
where client = "customer-domain"
and "2026-04-01" <= eventdate <= "2026-04-30"
pragma data.migration.all=true
```
