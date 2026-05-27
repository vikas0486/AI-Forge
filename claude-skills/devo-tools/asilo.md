# Asilo Aggregation Engine

**Confluence User Guide:** https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5803245569

---

## Quick Reference

| Region | Host | IP | Version |
|---|---|---|---|
| EU | `aso01-pro-eu-aws` | 172.17.1.41 | 7.5.5 |
| US | `asilo-1-pro-cloud-shared-aws-us-east-1` | 172.25.1.20 | 7.5.x |
| US3 | `asilo-1-pro3-cloud-shared-aws-us-east-2` | 172.28.42.80 | 7.5.x |
| APAC | `asilo-1-pro-cloud-shared-aws-ap-southeast-1` | 10.7.12.43 | 7.5.x |
| GCP | `asilo-1-pro-cloud-tef-gcp-europe-west1` | 10.6.3.203 | 7.5.x |

**Run as:** `logtrust` user | **Init script:** `/etc/init.d/asilo-engine`

**Commander shortcut (all regions):**
```bash
ssh <asilo-host> "sudo su logtrust -s /bin/bash -c 'source /etc/profile.d/asilo-engine.sh && \$COMMANDER_HOME/bin/asilo-commander <CMD> \$COMMANDER_OPTIONS <args>'"
```

---

## ⚠️ Logging — CRITICAL

**Asilo does NOT write pass/fail/status to any log file on disk.**
`/var/log/asilo-engine/asilo-engine.log` contains **JVM GC logs only** — never job state.

All job activity, failures, and command responses are written exclusively to Devo tables:

| Table | What it contains |
|---|---|
| `siem.logtrust.asilo.activity` | Job state changes, sanitize events, SEVERE failures, `Job failed` messages |
| `siem.logtrust.asilo.response` | Command responses (resume, stop, start, unregister, etc.) |

**Never SSH to check asilo logs for job status — always query these tables via Maqui.**

In `asilo.activity`, a healthy retry cycle looks like:
```
DEBUG  Sanitizing true Timing[1h[1m], validity: Validity(1648771200000, 173xxxxxxxx, List()), allowsFuture...
SEVERE Job failed
DEBUG  Sanitizing true Timing[1h[1m], ...   ← retrying
SEVERE Job failed
```
This alternating DEBUG/SEVERE pattern means Asilo is retrying — it is NOT stuck, it is working through the retry policy.

---

## Architecture & Query Flow

```
Asilo Engine
    │
    ├─[1. READ raw data]
    │   JDBC via Metamalote LB (EU: metamalote-eu.devo.internal:10100, IP: 172.17.43.110)
    │       ↓ NLB: private-metamalote-prod-eu → target group prod-eu-metamalote (10 targets)
    │   General/Shared/Customer Datanodes  ← raw source tables live here
    │       ↓ results returned
    │   Asilo computes aggregation (sum/count/avg)
    │
    ├─[2. WRITE aggr result]
    │   Sends _.alog/.alog.asaz via mm0 (special malote instances on self DNs)
    │   Self Datanodes (per region)
    │       └─ /var/logt/trN/bNN/t02/YYYY/MM/DD/<customer>/logtrust/aggr/<casparable_encoded>/
    │
    └─[3. DELETE old aggr files (sanitize before recompute)]
        Commands sent directly to mm0 on datanodes where old files reside
        mm0 port: 10111 (per trunk/instance)
```

**Key concepts:**
- **Casparable:** Aggregation definition (`.casp` file). Name is URL-encoded on disk.
- **Grain:** Time-granularity job for a casparable (`1h[1m]`, `5m`, `15s`, `30m`, `1m`)
- **mm0:** Set of malote instances (`malote@i0`–`malote@i7`) on self datanodes handling Asilo DELETE/WRITE. `malote@mm0` is inactive by design.
- **`delegation.allow.delegates: {"self"}`:** Restricts Asilo DELETE/WRITE dispatch to only self-owned datanodes. Scope: **dispatch path only** — does NOT scope the JDBC `lastEventdate` read scan. Applied in US and EU (Victor added to EU 2026-05-19). **Safe for EU:** Asilo only ever writes aggr output to self datanodes — never to customer dedicated DNs. Customer dedicated DNs hold raw events only. The catawiki aggr files were a one-time anomaly from the shared→dedicated migration (old aggr files migrated with the data). Once those are cleaned, no customer DN will ever have Asilo aggr files again.
- **Delegation management (UPDATED):** Dedicated datanode delegation is **no longer managed via Ansible group_vars** (`metamalote-general.yml` delegate_tags blocks). It is now managed by Mason and stored in the MySQL `installation_parenthood` table + `.db` config files. Adding a `cloud,<customer>` block to Ansible group_vars is still done for metamalote routing (so general metamalotes know to fan out queries to the dedicated DNs), but the Asilo deletion path uses the DB-managed delegation, not the Ansible config.

---

## lastEventdate Query — Sanitize Phase Detail

During the **sanitize phase** (before recompute), Asilo sends a `lastEventdate` JDBC query through the NLB to find the latest existing aggregation file date across **all datanodes**. This scan starts from the casparable's registered start date (e.g. `2022-04-01`) and fans out to every datanode in the cluster.

**Why it times out under heavy load:**
- EU NLB `private-metamalote-prod-eu` has an idle connection timeout of ~350s
- Under PLEN-9169 load (~5K concurrent casparables), all 10 metamalote nodes are saturated
- The `lastEventdate` scan takes longer than the NLB idle timeout → connection dropped mid-query
- Asilo receives: `MaloteException[401]: java.net.ConnectException: Connection timed out`  
  or: `DataConnectivityException: java.io.EOFException`  
  or: `Input ended before CANCELED received metamalote-eu.devo.internal/172.17.43.110:10100`
- Grain logs `Job failed` → enters retry policy → eventually `FailedJob` after 91 retries

**This is NOT a file deletion problem.** Stopping/resuming or manually deleting aggr files does NOT fix this. The only fixes are:
1. Reduce MM load (stop competing casparables)
2. Increase NLB idle timeout to 3600s+ — infra team action
3. Engine restart with `--read-state-from <recent-date>` — shorter scan completes before timeout, but **kills all running jobs**

**`counter_v1` is immune** because its grains have windowed start dates (`15s<1d>` = scan only last 1 day, `5m<7d>` = scan only last 7 days) — the scan completes instantly, never timing out.

---

## mm0 Configuration (self datanodes)

- **Do NOT add `--drop-bad-delegates`** — causes mm0 to reject Asilo's delete commands
- **`--mafia-mode=lazy-use-cache`** — required for aggr file serving
- EU General Metamalote heap: `-Xms4G -Xmx80G` (upgraded CHG-10643, 2026-05-19)

**mm0 delete response:**
```
not-deleted: 0   → all deleted → proceed to compute
not-deleted: N   → N partition slots failed → DeletingJob retries until FailedDeletion
```
`N` = partition slots (trunk × bucket × date), not individual files.

---

## Aggregation Data on Disk

**Grain → path mapping (validated 2026-05-20, EU shared datanodes):**

| Grain | t-bucket | Path pattern | Granularity |
|---|---|---|---|
| g15000 (15s) | t02 | `/var/logt/tr<N>/b0<N>/t02/YYYY/MM/DD/<customer>/logtrust/aggr/<encoded>/g15000/_.alog` | Daily (one dir per day) |
| g300000 (5m) | t02 | `/var/logt/tr<N>/b0<N>/t02/YYYY/MM/DD/<customer>/logtrust/aggr/<encoded>/g300000/_.alog` | Daily (one dir per day) |
| g3600000 (1h) | t00/M | `/var/logt/tr<N>/b0<N>/t00/M/YYYY/MM/<customer>/logtrust/aggr/<encoded>/g3600000/_.alog` | Monthly (one dir per month) |

**Key:** 15s and 5m grains use `t02` with daily `YYYY/MM/DD` dirs. The 1h grain uses `t00/M` with monthly `YYYY/MM` dirs — no day subdirectory.

**Required:* casparable reference table (all 5, all grains — validated 2026-05-20):**

| Casparable | Grain | Granularity | Data Location | Encoded Name |
|---|---|---|---|---|
| `required:siem.logtrust.collector.counter` | g15000 (15s) | Daily | `t02/YYYY/MM/DD/<customer>/logtrust/aggr/` | `required_3asiem_2elogtrust_2ecollector_2ecounter_e56` |
| `required:siem.logtrust.collector.counter` | g300000 (5m) | Daily | `t02/YYYY/MM/DD/<customer>/logtrust/aggr/` | `required_3asiem_2elogtrust_2ecollector_2ecounter_e56` |
| `required:siem.logtrust.collector.counter` | g3600000 (1h) | Monthly | `t00/M/YYYY/MM/<customer>/logtrust/aggr/` | `required_3asiem_2elogtrust_2ecollector_2ecounter_e56` |
| `required:siem.logtrust.collector.counter_v1` | g15000 (15s) | Daily | `t02/YYYY/MM/DD/<customer>/logtrust/aggr/` | `required_3asiem_2elogtrust_2ecollector_2ecounter_5fv1_d04` |
| `required:siem.logtrust.collector.counter_v1` | g300000 (5m) | Daily | `t02/YYYY/MM/DD/<customer>/logtrust/aggr/` | `required_3asiem_2elogtrust_2ecollector_2ecounter_5fv1_d04` |
| `required:siem.logtrust.collector.counter_v1` | g3600000 (1h) | Monthly | `t00/M/YYYY/MM/<customer>/logtrust/aggr/` | `required_3asiem_2elogtrust_2ecollector_2ecounter_5fv1_d04` |
| `required:siem.lt.scoja.domain.counter` | g15000 (15s) | Daily | `t02/YYYY/MM/DD/<customer>/logtrust/aggr/` | `required_3asiem_2elt_2escoja_2edomain_2ecounter_fffff85b` |
| `required:siem.lt.scoja.domain.counter` | g300000 (5m) | Daily | `t02/YYYY/MM/DD/<customer>/logtrust/aggr/` | `required_3asiem_2elt_2escoja_2edomain_2ecounter_fffff85b` |
| `required:siem.lt.scoja.domain.counter` | g3600000 (1h) | Monthly | `t00/M/YYYY/MM/<customer>/logtrust/aggr/` | `required_3asiem_2elt_2escoja_2edomain_2ecounter_fffff85b` |
| `required:siem.lt.scoja.me.counter` | g15000 (15s) | Daily | `t02/YYYY/MM/DD/<customer>/logtrust/aggr/` | `required_3asiem_2elt_2escoja_2eme_2ecounter_fffff9af` |
| `required:siem.lt.scoja.me.counter` | g300000 (5m) | Daily | `t02/YYYY/MM/DD/<customer>/logtrust/aggr/` | `required_3asiem_2elt_2escoja_2eme_2ecounter_fffff9af` |
| `required:siem.lt.scoja.me.counter` | g3600000 (1h) | Monthly | `t00/M/YYYY/MM/<customer>/logtrust/aggr/` | `required_3asiem_2elt_2escoja_2eme_2ecounter_fffff9af` |
| `required:collectorConsumptions` | g3600000 (1h) | Monthly | `t00/M/YYYY/MM/<customer>/logtrust/aggr/` | `required_3acollectorconsumptions_7ca` |

**Notes:**
- `collector.counter` 15s/5m files confirmed on **self DNs** under `/self/` customer path
- `domain.counter` + `me.counter` 15s/5m confirmed on **shared DNs** under customer domain paths (signalit, versia, etc.)
- `collectorConsumptions` has **only 1h grain** — zero on t02 daily path
- Each customer domain has its own copy of the aggr dirs — partition distributed across trunks/buckets
- Files are binary encoded (epoch timestamp + aggregated values), not human-readable
- **1 file per customer domain per casparable/grain per day** — the only variable is `<customer>`. File count on a given day = number of active customer domains on that datanode. A drop in count vs previous day = customers missing aggregation data.

**Ansible count commands (validated):**
```bash
# 15s/5m grains — daily path (t02), per casparable per grain
ansible datanode-shared -f 5 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
'for casp in required_3asiem_2elt_2escoja_2edomain_2ecounter_fffff85b required_3asiem_2elt_2escoja_2eme_2ecounter_fffff9af; do
  for grain in g15000 g300000; do
    count=$(ls /var/logt/tr*/b*/t02/YYYY/MM/DD/*/logtrust/aggr/$casp/$grain/_.alog 2>/dev/null | wc -l)
    echo "$casp / $grain : $count"
  done
done'

# 1h grain — monthly path (t00/M)
ansible datanode-shared -f 5 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
'for casp in required_3acollectorconsumptions_7ca; do
  count=$(ls /var/logt/tr*/b*/t00/M/YYYY/MM/*/logtrust/aggr/$casp/g3600000/_.alog 2>/dev/null | wc -l)
  echo "$casp / g3600000 : $count"
done'
```

**EU catawiki datanodes (dedicated cluster):**
- `dn-1`: 172.17.42.67 — trunks tr0, tr1
- `dn-2`: 172.17.60.77 — trunks tr0, tr1
- Only tr0 and tr1 exist on catawiki DNs (not tr2–tr7)

**Grain subdirectory names:**
```
g15000    = 15s grain  (t02 daily)
g300000   = 5m grain   (t02 daily)
g3600000  = 1h grain   (t00/M monthly)
key       = key index files
gall      = all-time aggregation (seen in system.delegated.internal.table)
```

**EU status (as of 2026-05-20):**
- `domain.counter`, `me.counter`, `collector.counter`, `collectorConsumptions` — **NO aggr files exist on any EU datanode**
  - Cause: `stop-delete-unregister` was run on May 11 (audit confirmed) — that compound command deleted the files. Standalone `unregister` on May 12 only removed registry entries, NOT files.
  - Recovery: re-register + Asilo recalculates from raw source events (no backup/restore procedure exists)
- `collector.counter_v1` — ✅ present on EU self datanodes (near real-time)

---

## Configuration

**EU current config (as of Victor's restart 2026-05-19 21:00 UTC):**
```bash
--malote metamalote-eu.devo.internal:10100
--read-state-from 2026-01-01
--executor-strategy '-[1m]<1m->8h~"required:.*|alert:.*"; 4~"required:.*|alert:.*"; -[15m]<1m->30m; -[1h]<1m->8h; 16<5m->20m; 8<1h->1h; 10->12h; 4'
--pragma-data 'delegation.reaction.failed.connection.drop: false, input.buffer: 2048, decompression.buffer: 2048, proc.vault.name: "high"'
--pragma-commands 'delegation.reaction.failed.connection.drop: false, delay.more.data.min: 100, delegation.allow.delegates: {"self"}'
--pragma-delete 'data.file.deletion.strategy: "delete.permanently"'
--retrying-policy '20*10s[5s]; 50*1m-10m[1m]; 20*10m-20m[2m]'
--deletion-retrying-policy '20*60s-6h;12*6h'
--wait-after-deletion 0s
--deletion-interval-multiplier 1
--max-concurrent-delete-commands 3
JAVA_OPTS="-Xms16g -Xmx16g"   # Still 16g — not yet raised to 31g to match US
```

**US config differences vs EU:**

| Parameter | EU | US |
|---|---|---|
| `JAVA_OPTS` heap | -Xms16g -Xmx16g | -Xms31g -Xmx31g |
| `--pragma-data` vault | `proc.vault.name: "high"` | `proc.vault.name: "low"` |
| `--read-state-from` | `2026-01-01` | `2016-07-01` |
| `--executor-strategy` | Same as US (fixed 2026-05-19) | Same |
| `--pragma-commands` | Same as US (fixed 2026-05-19) | Same |

**CRITICAL quoting:** `{\"self\"}` in init script only. Shell strips `"` from `{"self"}` → JVM gets `{self}` → `Unknown identifier 'self'` → commands-off state.

**Ansible source:** `automation/ansible/environments/aws/<region>/<env>/group_vars/asilo.yml`

**`--read-state-from` impact on restart time:** Keep recent (≤11 days = ~15min restart; 4+ months = ~40min). Note: changing this does NOT skip the lastEventdate scan for already-registered grains — it only affects initial state load on startup.

**`--read-state-from` vs casparable `<from>` date — different things:**
| Parameter | Controls | Current EU value |
|---|---|---|
| `--read-state-from 2026-01-01` | Which saved state Asilo loads at engine startup (memory efficiency) | `2026-01-01` ✅ already set |
| `<from>` in `start`/`resume` | What date a casparable recalculates FROM (baked into job state) | `2022-04-01` (set by Victor May 12) |
Changing `--read-state-from` does NOT change the casparable recalculation start date. To change recalc start date: `stop → unregister → register → start <new-from-date>`.

---

## Grain Start Order (CRITICAL)

**Always:** `1h[1m]` first → wait until real-time → `5m` → `15s`

Never start all at once. `1h[1m]` does the heavy S3 backfill; starting others early causes resource contention.

---

## Grain States

| State | Meaning |
|---|---|
| `NewJob` | Registered, not yet started |
| `RunningJob` | Computing — verify timestamp is advancing (check twice, 10+ min apart) |
| `StoppedJob` | Manually stopped — resumable with `resume-job` |
| `DeletingJob` | Sanitizing — deleting old aggr files before recomputing |
| `FailedDeletion` | Deletion failed — aggr files on remote datanodes Asilo can't delete |
| `FailedJob` | (1) deletion variant → `resume-job --failed-deletion`; (2) generic after 91 retries → plain `resume-job` |

**FailedJob after 91 retries:** Once exhausted, Asilo promotes to `UnrecoveredException/FailedJob`. `--failed-deletion` flag is rejected. Use plain `resume-job`.

**global-state broadcast:** When Asilo engine restarts it broadcasts all casparables as `false,0,0,-`. This is **NOT a bulk deregister** — it is normal restart behaviour. Do not confuse this with unregister commands.

---

## Commander Operations Reference

All commands run inside the `sudo su logtrust` wrapper above.

```bash
list                                              # List all casparables and grain states
status <aggrId>                                   # Current state + timestamp for a casparable
start <aggrId> <from-date>                        # Start a new/reset casparable (only on NewJob)
stop <aggrId>                                     # Stop all grains
stop-job --deletion <aggrId> <grain>              # Stop a specific DeletingJob grain
resume <aggrId>                                   # Resume all stopped/failed grains
resume-job <aggrId> <grain>                       # Resume specific grain (StoppedJob / FailedJob)
resume-job --failed-deletion <aggrId> <grain>     # Resume FailedDeletion state only
delete-job-data <aggrId> <grain> <from> --until <to> --filter 'client = "<customer>"'
extend <aggrId> <to-date>                         # Extend aggregation end date
commands-on                                       # Re-enable command processing
stop-delete-unregister <aggrId>                   # ⚠ DESTRUCTIVE — stop + delete all aggr files + unregister. Last resort only.
unregister <aggrId>                               # Remove from registry ONLY — NO file deletion (confirmed via audit 2026-05-11)
register -f <aggrId>                              # Force re-register (bypasses validation checks)
start-job-import <aggrId> <grain> <from-date>     # Start grain in import mode — sets Sanitizing=false, bypasses checkSynch.delete entirely
```

**`stop-delete-unregister` vs `unregister` — CRITICAL DISTINCTION (audit-confirmed 2026-05-11):**
- `stop-delete-unregister` = compound command: stop + **delete all aggr files from all datanodes** + unregister
- `unregister` (standalone) = removes from registry **only** — aggr files remain on disk untouched
- `stop-delete-unregister` fires as two response events: one `stop-delete-unregister` and one `unregister` — the `unregister` event is the internal step, NOT a separate command
- The delete phase can be a **no-op** if grains are already in FailedJob/empty state (`Sanitizing false` = no files to delete). Confirmed: both May 11 10:43 and 23:16 executions deleted **zero files** because grains were already FailedJob

**Safe restart from a specific date without deleting existing files:**
```bash
# stop → unregister → register → start <from-date>
# Files from before <from-date> remain on disk (orphaned, harmless)
# Asilo recomputes only from <from-date> forward — much faster catchup
asilo-commander stop          <aggrId>
asilo-commander unregister    <aggrId>
asilo-commander register      <aggrId>           # or register -f if validation fails
asilo-commander start         <aggrId> 2026-01-01
```
Use when: you want to restart from a recent date (e.g. 2026-01-01) without the cost of recomputing 4 years of data, and without destroying existing aggr files.

**`start` vs `resume`:**
- `start` only works on `NewJob` state. Using `start` on a `StoppedJob` returns `"Job Stopped is not new"` — use `resume-job` instead.
- `stop-job --deletion` on a `FailedJob` returns `"nothing to do"` — use `resume-job` instead.

### FailedDeletion Recovery via unregister → register -f → start-job-import

When a casparable is permanently stuck in `FailedDeletion` and aggr files cannot be deleted (auth issues, network, missing cert), use this sequence to bypass checkSynch.delete entirely:

```bash
# 1. Unregister — releases from stuck deletion state (no aggregation data lost)
$COMMANDER_HOME/bin/asilo-commander unregister $COMMANDER_OPTIONS "<aggrId>"

# 2. Force re-register — bypasses validation
$COMMANDER_HOME/bin/asilo-commander register -f $COMMANDER_OPTIONS "<aggrId>"

# 3. Start in import mode — Sanitizing=false, skips deletion phase entirely
$COMMANDER_HOME/bin/asilo-commander start-job-import $COMMANDER_OPTIONS "<aggrId>" "1h[1m]" "<from-date>"

# 4. Verify state
$COMMANDER_HOME/bin/asilo-commander status $COMMANDER_OPTIONS "<aggrId>"
```

**When to use:** Only when blocking aggr files cannot be deleted (e.g. cert missing on customer dedicated DNs). Fix the root cause (deploy cert, delete files) in parallel — this bypasses the deletion but does not clean up the stale files.

**Unregister ≠ delete.** Standalone `unregister` does NOT delete aggr files — it only removes the casparable from Asilo's registry. Files on disk remain (orphaned but harmless). Only `stop-delete-unregister` (the compound command) actually deletes files. Confirmed via audit log (2026-05-11/12): standalone `unregister` ran on May 12 after `stop-delete-unregister` already deleted files on May 11.

**Command timeout ≠ failure.** If the client times out, the command was still sent. Verify via:
```bash
source ~/.zshrc && maquieu 'from siem.logtrust.asilo.response where client="self" and now()-1h <= eventdate < now() select eventdate, aggrId, jobId, state, message limit 20'
```

---

## Maqui Queries

```bash
# Command responses (what Asilo did in response to stop/resume/start)
source ~/.zshrc && maquieu 'from siem.logtrust.asilo.response where client="self" and now()-1h <= eventdate < now() select eventdate, aggrId, jobId, state, message limit 20'

# SEVERE failures for required:* (Job failed, exceptions)
source ~/.zshrc && maquieu 'from siem.logtrust.asilo.activity where aggrId ~ "required:" and level = "SEVERE" and now()-1h <= eventdate < now() select eventdate, aggrId, jobId, message, exception limit 20'

# All activity for specific casparables grouped by level (use in Devo web for chart)
from siem.logtrust.asilo.activity
where aggrId in {"required:siem.logtrust.collector.counter", "required:siem.lt.scoja.me.counter", "required:siem.lt.scoja.domain.counter", "required:siem.logtrust.collector.counter_v1", "required:collectorConsumptions"}
group every 3h by aggrId, level select count() as events

# unregister/register/stop-delete-unregister audit (check what commands ran in a date range)
source ~/.zshrc && maquieu 'from siem.logtrust.asilo.response where commandKind in {"unregister","register","stop-delete-unregister"} and "2026-05-10 00:00:00" <= eventdate < "2026-05-12 23:59:59" select eventdate, commandKind, aggrId, jobId, message group every 2h by commandKind, aggrId select count()'

# Blocking datanodes for stuck deletion
source ~/.zshrc && maquieu 'from system.delegated.internal.tableFile where "YYYY-MM-DD" <= eventdate < "YYYY-MM-DD" and tableName = "logtrust.aggr.<aggrId>.g<ms>" select path, instance(databaseinfo()) as datanode pragma data.migration.all'

# List all casparables in EU by state (count)
# Run via commander: list | awk ... or grep for state in output
```

**Devo web query tips:**
- `order by` is NOT supported in Maqui CLI — remove it or use Devo web
- `in {}` syntax for multiple values: `aggrId in {"val1", "val2"}`
- Do not put comma after `where` clause
- Group interval minimum in CLI is 1m — use Devo web for sub-minute grouping

---

## Stuck DeletingJob / FailedDeletion Playbook

**Root cause:** Aggr files exist on a customer cluster that Asilo cannot auto-delete (auth or delegation missing).

**Step 1 — Identify blocking datanodes:**
```bash
source ~/.zshrc && maquieu 'from system.delegated.internal.tableFile
where "YYYY-MM-DD" <= eventdate < "YYYY-MM-DD"
and tableName = "logtrust.aggr.required:siem.lt.scoja.domain.counter.g3600000"
select eventdate, path, instance(databaseinfo()) as datanode
pragma data.migration.all'
```

**Step 2 — Verify file count (before any delete):**

⚠️ Use `wc -l` only — never `find ... -delete` on datanodes without explicit user confirmation.
```bash
ssh <datanode> "sudo find /var/logt -path '*/<customer>/logtrust/aggr/required_3asiem*' \
  -name '*.alog' -not -path '*/backup/*' -type f | wc -l"
```

**`error: -` in deletion response** is a known bug in `JDBCRunner.scala:154-155` — Success returned without deletion ID shows as `-` instead of an actual error message. Do not treat this as "no error" — check `not-deleted: N` count instead.

**Step 3 — Manual file deletion on datanodes (if Asilo cannot auto-delete):**
```bash
# Delete specific date range — confirm file count first, run per trunk
ssh <datanode> "sudo find /var/logt/tr0 /var/logt/tr1 \
  -path '*/YYYY/MM/<customer>/logtrust/aggr/required_3a*' \
  -name '*.alog.asaz' | wc -l"
# After user confirmation — rm commands must be explicitly approved before running
```

**Step 4 — Resume deletion on Asilo:**
```bash
ssh <asilo-host> "sudo su logtrust -s /bin/bash -c 'source /etc/profile.d/asilo-engine.sh && \
  \$COMMANDER_HOME/bin/asilo-commander stop-job --deletion \$COMMANDER_OPTIONS \"<aggrId>\" \"<grain>\" && \
  \$COMMANDER_HOME/bin/asilo-commander resume-job --failed-deletion \$COMMANDER_OPTIONS \"<aggrId>\" \"<grain>\"'"
```

**Expected:** `FailedDeletion` → `DeletingJob` → `NewJob` → `RunningJob`

---

## asilo.jks — Customer Datanode Auth (UPDATED)

**Current behaviour (newer datanode deployments):**
`asilo.jks` is **no longer a separate required file**. Its key material has been merged into `metamalote.jks`. When a datanode is provisioned with the updated Ansible role, `metamalote.jks` covers both metamalote and asilo authentication — `asilo.jks` as a standalone file is not needed.

**How to verify on a datanode:**
```bash
# Newer DNs — asilo key is inside metamalote.jks, no separate file needed
ssh <datanode> "sudo ls -la /etc/logtrust/malote/.ks/metamalote.jks"

# Older DNs — may still have standalone asilo.jks
ssh <datanode> "sudo ls -la /etc/logtrust/malote/.ks/asilo.jks"
```

**What happened with catawiki (PLEN-9169, 2026-05-18):**
Catawiki's dedicated DNs (provisioned 2024) were missing both the standalone `asilo.jks` AND did not have the merged `metamalote.jks` with the asilo key. This caused every deletion attempt to return `not-deleted: N` → `FailedDeletion`. Martin manually deployed `asilo.jks` as a workaround (CHG-10531). On future newly provisioned DNs this is no longer a concern — the merged `metamalote.jks` covers it.

**Why panda/talion were not affected:** Provisioned earlier when `asilo.jks` was still deployed explicitly, so they had it. Catawiki was provisioned in the transition period where the merge had happened but the new DNs didn't get the updated cert.

---

## EU Casparable Inventory (Snapshot: 2026-05-20)

**Total: 4,904 casparables | ~12,003 grain-instances**

### Overall Grain Health

| State | Count |
|---|---|
| RunningJob | 11,759 |
| StoppedJob | 203 |
| FailedJob | 41 |

### Categories by Domain

| Category | Casparables | Grains Used |
|---|---|---|
| Customer: Named (no @domain) | 3,073 | 1m / 5m / 30m / 1h |
| Customer: Training | 400 | 1m / 5m / 30m / 1h |
| Internal: Self | 334 | 1m / 5m / 30m / 1h |
| Customer: Gecko | 179 | 1m / 5m / 30m / 1h |
| Customer: SignalIT | 124 | 1m / 5m / 30m / 1h |
| Customer: Squalio | 119 | 1m / 5m / 30m / 1h |
| Customer: PandaSecurity | 91 | 1m / 5m / 30m / 1h |
| Test/Demo | 86 | 1m / 5m / 1h |
| Customer: Deloitte | 70 | 1m / 5m / 30m / 1h |
| Customer: 11paths | 59 | 1m / 5m / 30m |
| Customer: Allot | 50 | 1m / 5m / 1h |
| Customer: Indra | 50 | 1m / 5m / 1h |
| Customer: Ibuhoo | 40 | 1m / 5m / 1h |
| Internal: InternalIT | 31 | 1m / 5m / 1h |
| Customer: Tecnocom | 28 | 1m / 5m / 1h |
| Customer: Gonet | 23 | 1m / 5m / 1h |
| Customer: HCL/Eucsfc | 20 | 1m / 5m / 30m / 1h |
| Customer: Caixabank | 9 | 1m / 5m / 30m |
| Customer: Bitdefender | 10 | 1m / 5m / 30m / 1h |
| Customer: Westcon | 9 | 1m / 5m / 1h |
| Customer: Itscid360 | 9 | 1m / 5m / 1h |
| Customer: Tissat | 13 | 1m / 5m / 1h |
| Customer: Visiativ | 13 | 1m / 5m / 30m |
| Customer: Getd | 14 | 1m / 5m / 30m |
| Other (telefonica, misc) | 24 | 15s / 1m / 5m / 1h |

**Grain types present:** Most use `1m + 5m + 1h` triad. Some use `30m` instead of `1h` (SignalIT, Gecko, 11paths, Caixabank). Special: `15s`, `1h[1m]` (required:* only), `15s<1d>`, `5m<7d>`, `1m<1d>` (counter_v1 / tirea).

### Required:* Platform Casparables — Status

| AggrID | Grain | State | Latest | Lag |
|---|---|---|---|---|
| required:siem.logtrust.collector.counter | 15s | RunningJob | 2024-07-15 | ~22mo 🔴 |
| required:siem.logtrust.collector.counter | 5m | RunningJob | 2024-07-17 | ~22mo 🔴 |
| required:siem.logtrust.collector.counter | 1h[1m] | RunningJob | 2024-11-13 | ~18mo 🔴 |
| required:siem.lt.scoja.domain.counter | 15s | RunningJob | 2024-07-12 | ~22mo 🔴 |
| required:siem.lt.scoja.domain.counter | 5m | RunningJob | 2024-07-12 | ~22mo 🔴 |
| required:siem.lt.scoja.domain.counter | 1h[1m] | RunningJob | 2024-09-20 | ~20mo 🔴 |
| required:siem.lt.scoja.me.counter | 15s | RunningJob | 2024-07-13 | ~22mo 🔴 |
| required:siem.lt.scoja.me.counter | 5m | RunningJob | 2024-07-14 | ~22mo 🔴 |
| required:siem.lt.scoja.me.counter | 1h[1m] | RunningJob | 2024-12-03 | ~17mo 🔴 |
| required:collectorConsumptions | 1h[1m] | RunningJob | 2024-10-07 | ~19mo 🔴 |
| required:siem.logtrust.collector.counter_v1 | 15s<1d> | RunningJob | 2026-05-18 20:31 | ~1d ✅ |
| required:siem.logtrust.collector.counter_v1 | 5m<7d> | RunningJob | 2026-05-17 | ~3d 🟡 |
| required:siem.logtrust.collector.counter_v1 | 1h[1m] | RunningJob | 2024-11-20 | ~18mo 🔴 |

### Failed Jobs (41 grain-instances, 21 casparables)

| Pattern | Casparables | Latest | Notes |
|---|---|---|---|
| Old recalc — never progressed | cc_prisaradio, cc_ssancho, cc_sabis_ctx, cc_techtiws, cc_rs, cc_imagenio, cc_beehackers, cc_training20181203, cc_bigdatapfs@training, cc_andresnaranjo@training | 2022-04-01 | Likely orphaned — check if domain active before resuming |
| Recent stuck | cc_mercadona_poc (1m), cc_redelectrica@deloitte (1m) | 2026-05-14 | Investigate |
| All 3 grains failed | cc_tirea (1m<1d>, 5m<7d>, 1h) | 2026-05-06 – 2026-05-12 | |
| telefonica | telefonica:webserver httpstat (1m, 5m) | 2025-04 | |

### Stopped Jobs (203 grain-instances)

**Pattern:** ~95% stopped on **2026-05-18 ~04:00–04:47 UTC** (09:30–10:17 IST) — mass stop by Victor during the Jenkins/EC2 incident. These are intentional stops, not crashes. Need explicit `resume-job` per grain to recover.

Accounts affected: training, demo, poc, test, blueliv, kpmg, cursoimagenio, testfake, capgemini, paloalto_test, etc.

Older stops (not May-18): cc_onboarding (2024-06), cc_tutorial (2025-10), cc_pcantos2@training (2024-05).

---

## PLEN-9169 — EU Mass Recalculation (Active, started 2026-05-12)

**Scope:** ~305 EU casparables recalculating from 2022-04-01. Started by Victor.
- ~900+ concurrent JDBC streams → ~120,000 connections across 10-node metamalote LB (~12,000/node)
- EU casparable population as of 2026-05-20: **5,073 total**
  - `cc_*` (customer casparables): 4,886
  - `required:*` (platform): 5
  - `count:*`: 11
  - `secint:*`: 78
  - `telefonica:*`: 15
- State breakdown: ~4,963 RunningJob | ~28 FailedJob | ~80 StoppedJob | ~1 NewJob

**Timeline of required:* mishandling (May 2026):**

| Date | Who | Action | Effect |
|---|---|---|---|
| 2026-05-11 10:43 | Victor | `stop-delete-unregister` on `domain.counter` — **audit confirmed zero files deleted** (15s/5m already FailedJob, 1h `Sanitizing false` = no old files to delete). Re-registered 24s later. | No data loss |
| 2026-05-11 23:16 | Victor | `stop-delete-unregister` on `me.counter` — **audit confirmed zero files deleted** (grains at 0,0,0 / DeletingJob-failed state). Re-registered 3 min later. | No data loss |
| 2026-05-12 00:33 | Victor | Standalone `unregister` on `collector.counter`, `domain.counter`, `me.counter` — **no file deletion** (unregister = registry only). All three re-registered at 00:37–00:38. | No data loss |
| 2026-05-12 | Vikash | Re-registered all 3 casparables with `--read-state-from 2026-04-01` (45-day window). **Why 2026-04-01:** Starting from 2022 would take weeks to catch up; 45 days covers recent data and catches up to real-time quickly. Started grains in correct order: `1h[1m]` first → `5m` → `15s`. | Fast recalculation path |
| 2026-05-12+ | — | catawiki FailedDeletion blocks all required:* grains — see deletion loop below | All 5 hit FailedJob after 91 retries |
| 2026-05-18 | Martin | Deployed `asilo.jks` to catawiki DNs (CHG-10531) | Unblocked deletion |
| 2026-05-18 | Vikash | Manually deleted catawiki aggr files 2024+2025 from dn-1 and dn-2 | FailedDeletion resolved |
| 2026-05-19 | Vikash | Resumed all required:* grains | All 5 now RunningJob |
| 2026-05-20 | — | 1h[1m] grains advancing; 15s/5m stuck at Jul 2024 due to NLB timeout | Ongoing |

**Why catawiki blocked ALL required:* grains — the deletion cursor freeze:**

When Asilo recalculates a casparable, it must first delete old aggr files for the date range being recomputed (sanitize phase). Asilo tracks a **deletion cursor** — it will not mark a time window as complete until every aggr file for that window is confirmed deleted across all datanodes.

Catawiki's dedicated DNs (provisioned April 2026) were missing `asilo.jks` — so every delete command routed through:
```
Asilo → Metamalote LB → Target metamalote → Catawiki dedicated DN → AUTH FAIL → not-deleted: N
```
Asilo retried up to **91 times** per grain. After 91 retries → `FailedJob`. The deletion cursor stayed frozen at the blocked date. **No grain could advance past that date** — including all other required:* casparables sharing the same metamalote LB. Every grain that touched a date range with catawiki files was trapped in the same retry loop.

Fix required two steps in sequence:
1. Deploy `asilo.jks` to catawiki DNs (Martin, CHG-10531, 2026-05-18) — fix auth
2. Manually delete the blocking aggr files from catawiki dn-1 and dn-2 — unfreeze the cursor
3. `resume-job` (plain, not `--failed-deletion`) on each FailedJob grain — restart from frozen point

**"Bulk deregister" clarification:**
Victor/Samson claimed Vikash bulk-deregistered all EU casparables. This is false. Maqui audit (`siem.logtrust.asilo.response` with `commandKind in {"unregister","register","stop-delete-unregister"}`) shows only individual commands for 3 casparables. The `false,0,0,-` global-state broadcast seen at the time was the Asilo engine restart — not a bulk deregister.

**Root cause of required:* stall — lastEventdate query timeout:**
See "lastEventdate Query" section above. Affects 15s/5m grains most (stuck Jul 2024). 1h[1m] grains progressing slowly.

**Status as of 2026-05-20 (before Samson manual stop):**

| Casparable | 1h[1m] | 5m | 15s |
|---|---|---|---|
| collector.counter | 2024-11-13 ✅ advancing | 2024-07-17 ⚠️ stuck | 2024-07-15 ⚠️ stuck |
| domain.counter | 2024-09-20 ✅ advancing | 2024-07-12 ⚠️ stuck | 2024-07-12 ⚠️ stuck |
| me.counter | 2024-12-03 ✅ advancing | 2024-07-14 ⚠️ stuck | 2024-07-13 ⚠️ stuck |
| collectorConsumptions | 2024-10-06 ✅ advancing | — | — |
| collector.counter_v1 | 2024-11-20 ✅ advancing | 2026-05-17 ✅ real-time | 2026-05-18 ✅ real-time |

**Status as of 2026-05-21 (current):**

All required:* manually stopped by Samson at **2026-05-20 13:17 UTC** (32-second sequence — all 4 in one batch). Audit confirmed via `siem.logtrust.asilo.response` `commandKind=stop`. They were advancing well at the time of stop.

| Casparable | 1h[1m] | 5m | 15s | Stopped at |
|---|---|---|---|---|
| collector.counter | 2024-12-05 🔴 StoppedJob | 2024-07-31 🔴 StoppedJob | 2024-07-15 🔴 StoppedJob | 13:17:22 UTC |
| domain.counter | 2024-09-20 🔴 StoppedJob | 2024-07-12 🔴 StoppedJob | 2024-07-12 🔴 StoppedJob | 13:17:30 UTC |
| me.counter | 2026-04-21 🔴 StoppedJob | 2026-04-21 🔴 StoppedJob | 2026-04-21 🔴 StoppedJob | 13:17:37 UTC |
| collectorConsumptions | 2024-11-24 🔴 StoppedJob | — | — | 13:17:05 UTC |
| collector.counter_v1 | 2026-04-21 🔴 StoppedJob | 2026-05-13 🔴 StoppedJob | 2026-05-19 🔴 StoppedJob | (separate stop) |

**Overall casparable state (2026-05-21):** 207 grain-instances running (alert:*, telefonica:*, utm:*, secint:*, stat:*, etc.) | required:* and cc_* all StoppedJob

**Running casparable health (2026-05-21 ~16:30 UTC):**
- `alert:*`, `telefonica:nm:url_status`, `utm:virus` — ✅ all grains LIVE / <71m lag (1h bucket normal)
- `secint:*`, `fw:*`, `panda:*`, `utm:appCtrl/emailFilter/vpn/webFilter`, `avm:*`, `custom_atento:*`, `stat:*` — 🔴 catching up, 3–50d behind (started 2026-04-01)
- `telefonica:webserver:httpstat` — 390d behind (started 2022-04-01)
- `secint:proxy_traffic_heatcalendar`, `secint:web_anonymous_table` — 825–837d behind
- `cc_pandasecurity:vmaud582` — 1511d behind (stuck at 2022-04-01, never progressed)

**⚠️ NEW STRATEGY (2026-05-21, Samson announcement ~16:43 IST):**

Samson/Victor/Pablo have decided to **disable the aggregation pragma globally** and run **Tabula Rasa** on EU shared.

**What changes:**
1. **Pragma change** — aggregation usage disabled across all casparables. All queries will hit raw data directly instead of pre-aggregated results.
2. **+3 EU shared datanodes** (+60% capacity) being spun up to absorb the extra raw-query CPU load.
3. **Tabula Rasa on EU shared** — domain affinity reset to redistribute load across new+old nodes.

**Why:** Casparables producing corrupted recalculations due to persistent connection errors (203 SEVERE "Job failed" errors). Pre-aggregated data deemed unreliable — raw data is authoritative.

**Note:** The SEVERE "Job failed" messages are the normal Asilo retry cycle (DEBUG sanitize → SEVERE failed → DEBUG retry), NOT data corruption. The aggr data written before the catawiki block was valid. This is nonetheless their call.

**Impact:**
- Dashboard/widget query latency will increase (raw scans vs pre-aggr reads)
- EU shared performance issues expected for ~7 days while load stabilizes
- Alerts: no impact (alerts query source tables directly, independent of casparables)
- No data loss — correctness fix only

**Rollback path:** Once metamalote capacity stabilizes, casparables need full recalculation (delete-data + restart) before aggregation pragma can be re-enabled.

**Timeline:** Executing in ~2–3h from 16:43 IST (2026-05-21) = ~19:00–20:00 IST / 13:30–14:30 UTC.

**What to monitor post-execution:**
- EU shared datanode count (3 new nodes up)
- MM JDBC connection count — raw queries mean more streams
- Dashboard latency in EU
- Tabula Rasa completion status

**⚠️ Asilo operations PAUSED** — Samson/Victor own recovery. Read-only (list/status only). Do NOT resume/stop/start any casparable.

**Resolution history (2026-05-18/19):**
- Martin deployed `asilo.jks` to catawiki dedicated DNs (CHG-10531, 2026-05-18)
- Vikash deleted all blocking catawiki aggr files (Jul 2024 – May 18 2026) from both dn-1 and dn-2 (2026-05-18)
- Vikash resumed all 5 `required:*` casparables — all 3 grains (2026-05-18)
- Samson applied US executor-strategy + `delegation.allow.delegates: {"self"}` to EU Asilo (CHG-10649, 2026-05-19)
- Samson reloaded Asilo engine — `systemctl daemon-reload` + service restart (2026-05-19)
- Samson manually stopped all required:* at 13:17 UTC 2026-05-20 (Phase 1 plan from CHG-10649)
- Samson also did unregister → register → start-import on `me.counter` at 17:40 UTC 2026-05-20

**Watch script:** `~/Documents/Scripts/asilo-watch-resume.sh` (local copy)
- Auto-resumes `required:*` FailedJobs every 5min using plain `resume-job`
- Deploy: `scp ~/Documents/Scripts/asilo-watch-resume.sh aso01-pro-eu-aws:/tmp/`
- Run: `ssh aso01-pro-eu-aws "sudo su logtrust -s /bin/bash -c 'source /etc/profile.d/asilo-engine.sh && nohup /tmp/asilo-watch-resume.sh >> /tmp/asilo-watch-resume.log 2>&1 &'"`

**Check metamalote load:**
```bash
for i in {1..10}; do conns=$(ssh metamalote-$i-pro-cloud-general-aws-eu-west-1 "sudo ss -tn state established '( dport = :10100 or sport = :10100 )' 2>/dev/null | tail -n +2 | wc -l" 2>/dev/null); load=$(ssh metamalote-$i-pro-cloud-general-aws-eu-west-1 "cat /proc/loadavg 2>/dev/null | awk '{print \$1}'" 2>/dev/null); echo "mm-$i $conns $load"; done
```

**EU MM post-upgrade baseline (2026-05-19, after CHG-10643, -Xmx80G):**

| MM | CPU% | RAM Used | Heap RSS | Swap | Threads |
|---|---|---|---|---|---|
| MM-1 | 103% | 81Gi/124Gi | 81.9 GB | 0 | 32 |
| MM-2 | 81% | 35Gi/124Gi | 33.2 GB | 0 | 32 |
| MM-3 | 86% | 83Gi/124Gi | 79.7 GB | 0 | 32 |
| MM-4 | 89% | 87Gi/124Gi | 86.3 GB | 0 | 32 |
| MM-5 | 75% | 87Gi/124Gi | 85.2 GB | 0 | 32 |
| MM-6 | 79% | 71Gi/124Gi | 69.4 GB | 0 | 32 |
| MM-7 | 74% | 84Gi/124Gi | 82.9 GB | 0 | 32 |
| MM-8 | 82% | 76Gi/124Gi | 77.7 GB | 0 | 32 |
| MM-9 | 66% | 79Gi/124Gi | 75.5 GB | 0 | 32 |
| MM-10 | 69% | 82Gi/124Gi | 81.6 GB | 0 | 32 |

MM-4 and MM-5 RAM to watch (87GB/124GB). High CPU due to PLEN-9169 ~5K casparables running simultaneously.

---

## Known Issues

| Issue | Cause | Fix |
|---|---|---|
| `Unknown identifier 'self'` / commands-off | `{"self"}` in pragma → shell strips quotes → JVM gets `{self}` | Change to `{\"self\"}` in init script |
| Metamalote OOM crash (EU general) | Heap set to 48G (above 32GB JVM boundary) | Reverted to 31G; now upgraded to 80G on x2gd.2xlarge |
| mm0 rejecting Asilo delete operations | `--drop-bad-delegates` flag on self DN metamalote.service | Removed flag, restarted mm0 on all 5 self DNs |
| catawiki FailedDeletion on all grains | `asilo.jks` missing from catawiki DNs (provisioned 2024 in transition period before `metamalote.jks` merge) | Martin manually deployed 2026-05-18 (CHG-10531); files manually deleted. Newer DNs use `metamalote.jks` — no separate `asilo.jks` needed |
| `required:*` FailedJob `not-deleted: 16` | No `cloud,catawiki` delegation in metamalote routing → delete commands routed to shared DNs, aggr files on dedicated DNs unreachable | MR #134 merged: adds `cloud,catawiki` → `datanode-catawiki` delegation. Note: Asilo deletion itself uses DB-managed delegation (Mason/`installation_parenthood`); the Ansible block fixes metamalote query routing |
| 15s/5m grains stuck at Jul 2024 | NLB idle timeout drops lastEventdate scan under PLEN-9169 load | Pending NLB timeout increase; or engine restart with `--read-state-from 2024-07-01` |

---

## EU Shared Datanode Malote GC Tuning (DN2, May 2026)

**Context:** EU shared datanodes (5 nodes) experiencing malote fullGC due to -Xmx31G heap insufficient for live data load (44-47GB). Validated fix on `datanode-2-pro-cloud-shared-aws-eu-west-1` malote@i2 and @i5.

**Validated config (from `malote_tweak.md`):**
```ini
JAVA_OPTIONS=-Xms55G -Xmx55G -XX:G1HeapRegionSize=32m -XX:G1ReservePercent=15 \
  -XX:InitiatingHeapOccupancyPercent=35 -XX:G1MixedGCCountTarget=16 \
  -XX:MaxGCPauseMillis=200 -XX:ParallelGCThreads=16 -XX:ConcGCThreads=4
```
Transparent hugepages: `always` / `defer+madvise` (runtime only — not persisted across reboot).

**GC result (from `siem.logtrust.malote.gc`, instance format: `datanode-2-pro-cloud-shared-aws-eu-west-1-i2`):**

| Period | i2 Full GC/day | i5 Full GC/day |
|---|---|---|
| Apr 28 – May 5 (baseline) | 8,000 – 12,220 | 61 – 767 |
| May 6 – May 12 (tuning active) | **0** | **0** |
| May 13 – May 19 (Ansible reverted i5 + signalit spike) | ~0–2 | 3,428 – 7,597 |

**Current state (2026-05-20):** Both i2 and i5 reverted by Ansible deployment — `JAVA_OPTIONS` removed from `.conf` files, running on default `-Xmx31G`. Ansible `group_vars` fix drafted but not yet merged (pending MR).

**Maqui query for Full GC validation:**
```bash
source ~/.zshrc && maquieu 'from siem.logtrust.malote.gc where client = "self" and (instance = "datanode-2-pro-cloud-shared-aws-eu-west-1-i2" or instance = "datanode-2-pro-cloud-shared-aws-eu-west-1-i5") and "2026-04-28" <= eventdate < "2026-05-20" and message ~ "Pause Full" group every 1d by instance select count() as fullgc_count'
```

**Config files:** `/etc/logtrust/systemd/malote/<hostname>/i2.conf` (and `i5.conf`) — `JAVA_OPTIONS` line added here, NOT in separate `malote.javaoptions` file (that file is not read by startup script).

**Permanent fix:** Add `malote_xms/malote_xmx: "55G"` + G1GC vars to `ansible/environments/aws/eu/pro/group_vars/datanode-shared.yml` and expose them in `malotev2/roles/malote/templates/malote.javaoptions.j2`.

---

## Case Study: EU General Metamalote NVMe Mount Failure (CHG-10643, 2026-05-19)

**Impact:** All 10 EU general metamalotes unable to serve queries for ~7 hours.

**Root cause:** x2gd.xlarge → x2gd.2xlarge (Graviton) reorders NVMe devices:

| Device | x2gd.xlarge | x2gd.2xlarge |
|---|---|---|
| `nvme0n1` | Root EBS | Root EBS |
| `nvme1n1` | Instance store ← fstab pointed here | EBS volume ← wrong! |
| `nvme2n1` | — | Instance store ← correct |

`fstab` still referenced `/dev/nvme1n1` → mount failed on boot → metamalote crash loop.

**Remediation (per node):**
```bash
mkfs.xfs /dev/nvme2n1
# Update fstab: nvme1n1 → nvme2n1
mount /var/logt/data && chown logtrust:lookups /var/logt/data
# Rsync lookups from bitdefender nodes, then restart metamalote
```

**Ansible fix:** `metamalote_lookup_disk: '/dev/nvme2n1'` in EU Pro `metamalote-general.yml` (NOT base `metamalote.yml`).

**Prevention:** Use `/dev/disk/by-id/` symlinks instead of device names.
