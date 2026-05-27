---
name: devo-alert
description: Devo Alert management — Flow/Pilot/Cockpit architecture, alert context DB schema, period staggering (anti-flooding), TAPU token manager, cross-domain injection, XSOAR duplicate alert fix.
argument-hint: "[alert-name|ISM-ticket|issue]"
tags: [alert, flow, pilot, cockpit, tapu, xsoar, anti-flooding]
---

## Alert Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Cockpit (Web UI)                                           │
│  - Create/Edit Flows (Alert Definitions)                   │
│  - Start/Stop Flows                                         │
│  Reads from: alert_context.default_params                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Database (MySQL) - logtrust schema                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ alert_context (Flow Definitions)                     │  │
│  │ - id, name, default_params (JSON)                    │  │
│  │ - What Cockpit UI displays/edits                     │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ alert_context_subscription (Running Instances)       │  │
│  │ - id, alert_context_id, params (JSON)                │  │
│  │ - What Pilot reads to determine enabled contexts     │  │
│  │ - status: 1=enabled/active, 0=disabled/inactive      │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Database (MySQL) - pilot schema  ⚠️ MOST CRITICAL         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ pilot.contexts (Actual Runtime Execution)            │  │
│  │ - id (binary UUID), name, running, loaded            │  │
│  │ - template_id (controls Cockpit "Parent template")   │  │
│  │ - params (JSON) — DIFFERENT schema from logtrust     │  │
│  │   Fields: flowKind, query, tableName, timezone,      │  │
│  │           priority, period, backPeriod               │  │
│  │ - THIS is what Pilot actually uses at runtime        │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Pilot (Kubernetes - pilotserver-alerts StatefulSet)       │
│  - Loads contexts from pilot.contexts at runtime            │
│  - Executes Maqui queries via Malote                        │
│  - Dispatches to siem.logtrust.alert.info table             │
│  - Logs to siem.logtrust.flow.out                          │
└─────────────────────────────────────────────────────────────┘
```

**Key terms:**
- **Flow**: Alert definition (query logic, schedule, recipients)
- **Context**: Running instance of a Flow (loaded in Pilot)
- **Pilot**: Kubernetes-based alert execution engine
- **Cockpit**: Web UI for managing Flows

---

## Database Tables

### alert_context (Flow Definitions)

**Key Fields:** `id`, `name`, `default_params` (JSON)

```json
{
  "object": {
    "kind": "each" | "rolling",
    "period": 3600000,
    "sourceLinqQuery": "from box.all.win where...",
    "template": { "name": "each", "type": "each" }
  }
}
```

### alert_context_subscription (Running Instances)

**Key Fields:** `id`, `alert_context_id`, `params` (JSON), `status` (1=enabled, 0=disabled), `policy_type`, `creation_date`

```json
{
  "object": {
    "kind": "each" | "rolling",
    "period": 3600000,
    "backPeriod": 86400000,
    "sourceLinqQuery": "from box.all.win where...",
    "threshold": 3
  },
  "template": { "name": "each", "type": "each" }
}
```

**Relationship:** `alert_context (1) ──> (N) alert_context_subscription` (one Flow, many customer subscriptions)

### pilot.contexts (Actual Runtime — MOST CRITICAL)

**Key Fields:** `id` (binary UUID), `name`, `running`, `loaded`, `server_id`, `template_id` (binary UUID → `pilot.templates`), `params` (JSON)

**pilot.contexts.params schema** (DIFFERENT from logtrust):
```json
{
  "flowKind": "rolling",
  "query": "from box.all.win select target_username...",
  "tableName": "box.all.win",
  "timezone": "GMT",
  "priority": 2,
  "period": 7200000,
  "backPeriod": 691200000
}
```

Key differences vs logtrust schema: `flowKind` (not `$.object.kind`), `query` (not `$.object.sourceLinqQuery`), `tableName` explicit, no nested `object` wrapper.

**template_id values (binary UUID):**
- Rolling: `CA1E329E91084FB4B929B414A3851A1F`
- Each: query `SELECT HEX(id), name FROM pilot.templates;`

**Access via sql alias (US):**
```bash
source ~/.zshrc && sql usa_pro
# Then: SELECT id, name, running, loaded, template_id, params FROM pilot.contexts WHERE name LIKE '%SUC70035%';
```

**⚠️ Double-JSON Encoding Bug:** If `pilot.contexts.params.query` is `"\"from box.all.win..."` (double-encoded), Pilot fails with `Error while converting json to map`. Fix with a direct literal UPDATE:
```sql
UPDATE contexts
SET params = '{"flowKind":"rolling","query":"from box.all.win select...","tableName":"box.all.win","timezone":"GMT","priority":2,"period":7200000,"backPeriod":691200000}'
WHERE id = UNHEX('9FD0882C9D1F465C8AC300EDB30BC86A');
```
Verify: `SELECT JSON_EXTRACT(params, '$.query') FROM contexts WHERE name LIKE '%SUC70035%';` — must NOT start with a backslash-quote.

**Three-Layer Fix Checklist (for any template/query changes):**
- [ ] Update `logtrust.alert_context.default_params` (Cockpit display)
- [ ] Update `logtrust.alert_context_subscription.params` (Pilot load source)
- [ ] Update `pilot.contexts.params` (runtime — most critical)
- [ ] Update `pilot.contexts.template_id` (if changing rolling/each type)
- [ ] Restart relevant Pilot pod

**CRITICAL — Cockpit edits do NOT auto-sync to subscriptions or pilot.contexts.** All three tables must be kept in sync manually.

---

## Template Types (each vs rolling)

| Aspect | "each" | "rolling" |
|--------|--------|-----------|
| **State** | No state | Maintains queryPointer |
| **Restart Behavior** | Fresh start from now() | Resume from last queryPointer |
| **Historical Data** | ❌ Only real-time/future | ✅ Yes (if queryPointer null) |
| **Reprocessing** | Reprocesses windows | Incremental only |
| **BackPeriod** | Window size each cycle | Initial lookback (first run only) |
| **QueryPointer** | Not used | Persisted externally |

**Common misconception:** ❌ "each" = event-triggered, "rolling" = time-based. ✅ Both are time-based with period boundaries. Difference is state management.

**ReadingTime behavior:**
- `each`: `readingTime = now()` on every start — never processes historical data
- `rolling` (first load): `readingTime = now() - backPeriod` — can catch up historical
- `rolling` (subsequent): resumes from stored queryPointer

---

## Alert Lifecycle (condensed)

1. **Create Flow** → rows in `alert_context` + `alert_context_subscription` (status=0)
2. **Start Flow (Cockpit)** → `alert_context_subscription.status = 1`; Pilot does NOT load immediately — requires pod restart
3. **Pod Restart** → Pilot scans subscriptions where `status=1`, loads contexts into `pilot.contexts`, starts WorkForce threads
4. **Execution Cycle** → waits for period boundary, runs Maqui query via Malote, if results ≥ threshold writes to `siem.logtrust.alert.info` and logs `ALERT:` to `siem.logtrust.flow.out`
5. **Stop Flow (Cockpit)** → `status=0`; context keeps running until next pod restart
6. **Alert dispatch table:** `siem.logtrust.alert.info` (column: `context`, NOT `contextName`; `status=0` = success/dispatched)
7. **`alerts.dispatched` does NOT exist** — always use `siem.logtrust.alert.info`
8. **`startFailedContexts` in pod logs is cumulative** (not current state) — verify via `flow.out` "Started context" messages instead

**Cockpit UI cache:** If UI shows stale values after edit, hard refresh (Ctrl+Shift+R) or verify DB directly — Cockpit reads `alert_context.default_params` but Pilot uses `pilot.contexts.params`.

---

## Kubernetes Infrastructure

**StatefulSet:** `pilotserver-alerts`
**Namespaces:** `devo-prod-us-core` (US), `devo-prod-eu-core` (EU), etc.
**Replicas:** 12 (US); pods named `pilotserver-alerts-0` through `pilotserver-alerts-11`
**Context assignment:** consistent hashing by context name — same context always on same pod

**Pirulo is the legacy alert context manager.** Context files at `/etc/logtrust/pilot/contexts/`. Use `pilot.contexts` MySQL table for runtime changes instead.

```bash
# Check pod status
source ~/.zshrc && kube get pods -n devo-prod-us-core | grep pilotserver-alerts

# Find which pod runs a context
source ~/.zshrc && maquius "from siem.logtrust.flow.out where now() - 1h < eventdate < now() and domain = 'curo' and weakhas(contextName, 'SUC70035') and weakhas(message, 'Thread started') select eventdate, host, contextName"

# Restart single pod
source ~/.zshrc && kube delete pod pilotserver-alerts-4 -n devo-prod-us-core

# Restart all pods (rolling, ~10-15 min for 12 pods)
source ~/.zshrc && kube rollout restart statefulset/pilotserver-alerts -n devo-prod-us-core

# Monitor rollout
source ~/.zshrc && kube rollout status statefulset/pilotserver-alerts -n devo-prod-us-core

# View pod logs
source ~/.zshrc && kube logs pilotserver-alerts-4 -n devo-prod-us-core --since=1h | grep SUC70035
```

**Restart sequence:** Stop Flow in Cockpit → wait 30-60s → restart pod → wait for 1/1 Ready → Start Flow in Cockpit → verify via flow.out logs

---

## Common Operations (SQL commands)

### Update Alert Query Logic

```sql
-- Update subscription (what Pilot loads)
UPDATE alert_context_subscription
SET params = JSON_SET(
    params,
    '$.object.sourceLinqQuery',
    'from box.all.win
select target_username as evTargetUserName
where 
    type = "security",
    eventID = 4723 or eventID = 4724,
    audit_result = "Success"
group every - by evTargetUserName
select count() as count where count >= 3'
)
WHERE id = 244048;

-- Update Flow definition (for Cockpit UI sync)
UPDATE alert_context
SET default_params = JSON_SET(
    default_params,
    '$.object.sourceLinqQuery',
    'from box.all.win ...'
)
WHERE id = 94052;
```

### Change Alert Period

```sql
-- Change to 4 hours (14400000ms)
UPDATE alert_context_subscription
SET params = JSON_SET(params, '$.object.period', 14400000)
WHERE id = 244048;

UPDATE alert_context
SET default_params = JSON_SET(default_params, '$.object.period', 14400000)
WHERE id = 94052;
```

### Change Template Type

```sql
-- Convert to rolling
UPDATE alert_context_subscription
SET params = JSON_SET(params, '$.object.kind', 'rolling')
WHERE id = 244048;

UPDATE alert_context
SET default_params = JSON_SET(default_params, '$.object.kind', 'rolling')
WHERE id = 94052;

-- Also update pilot.contexts.template_id (determines Cockpit "Parent template" display)
UPDATE pilot.contexts
SET template_id = UNHEX('CA1E329E91084FB4B929B414A3851A1F')
WHERE name LIKE '%SUC70035%';
```

### Enable / Disable Alert

```sql
UPDATE alert_context_subscription SET status = 0 WHERE id = 244048;  -- disable
UPDATE alert_context_subscription SET status = 1 WHERE id = 244048;  -- enable
```

### Find Alert by Name

```sql
SELECT acs.id, acs.status, ac.name,
    JSON_EXTRACT(acs.params, '$.object.kind') as template_kind,
    JSON_EXTRACT(acs.params, '$.object.period') / 3600000 as period_hours,
    JSON_EXTRACT(acs.params, '$.object.backPeriod') / 86400000 as backperiod_days
FROM alert_context_subscription acs
JOIN alert_context ac ON ac.id = acs.alert_context_id
WHERE ac.name LIKE '%SUC70035%';
```

---

## Troubleshooting

### Alert Not Dispatching

1. **Verify Flow status:**
   ```sql
   SELECT acs.status, acs.policy_type, JSON_EXTRACT(acs.params, '$.object.kind') as kind
   FROM alert_context_subscription acs WHERE acs.id = 244048;
   ```
   Check: `status=1`, `policy_type` ≠ `NO_NOTIFICATION`

2. **Check context loaded:**
   ```bash
   source ~/.zshrc && maquius "from siem.logtrust.flow.out where now() - 24h < eventdate < now() and domain = 'curo' and weakhas(contextName, 'SUC70035') and weakhas(message, 'Thread started') select eventdate, host"
   ```
   No results → context never loaded → restart pod

3. **Check query execution:**
   ```bash
   source ~/.zshrc && maquius "from siem.logtrust.flow.out where now() - 1h < eventdate < now() and domain = 'curo' and weakhas(contextName, 'SUC70035') and weakhas(message, 'executed new query') select eventdate, message"
   ```

4. **Check for errors:**
   ```bash
   source ~/.zshrc && maquius "from siem.logtrust.flow.out where now() - 1h < eventdate < now() and domain = 'curo' and weakhas(contextName, 'SUC70035') and (weakhas(message, 'Error') or weakhas(message, 'Exception')) select eventdate, message"
   ```

5. **Check dispatch records:**
   ```bash
   source ~/.zshrc && maquius "from siem.logtrust.alert.info where '2026-05-13' < eventdate < now() and eq(domain, 'curo') and weakhas(context, 'SUC70035') select eventdate, domain, context, status, alertContextSubscription, alertcreationdate limit 20"
   ```

6. **Check if other alerts firing (infra health check):**
   ```bash
   source ~/.zshrc && maquius "from siem.logtrust.flow.out where now() - 1h < eventdate < now() and domain = 'curo' and weakhas(message, 'ALERT:') select count()"
   ```
   If >0: infrastructure OK, problem is specific to this context (query logic, data availability)

### Context Not Loading After Restart

1. Verify pod restarted: `kube get pod pilotserver-alerts-4 -n devo-prod-us-core` (check AGE)
2. Verify subscription enabled: `SELECT status FROM alert_context_subscription WHERE id = 244048;`
3. Find correct pod:
   ```bash
   for i in {0..11}; do
     echo "Pod $i:"; source ~/.zshrc && kube logs pilotserver-alerts-$i -n devo-prod-us-core --since=5m | grep -c "SUC70035"
   done
   ```
4. Restart the correct pod

### Connection Errors (Code: 401)

```
[0:reader] - Error while executing query - [Code: 401, Kind: CONNECTION_ERROR, Recoverable: YES]
```

Causes: Malote/Metamalote overload, query timeout (>300s), Malote restart during query.
These are often transient — context auto-retries. Only investigate if persistent.
Check Malote health: `kube get pods -n devo-prod-us-core | grep malote`

---

## Alert Query Design & Security Best Practices

### audit_result Filtering

| Filter | Detects | Threshold | Time Window |
|--------|---------|-----------|-------------|
| `audit_result = "Success"` | Account takeover (post-compromise) | 3 (low) | 24h |
| `audit_result = "Failure"` | Brute force / password spray | 10 (high) | 1h |
| No filter | Too noisy, loses threat context | 5+ | — |

### Two-Alert Strategy (Recommended)

**Alert 1 — Multiple Successful Password Changes (SUC70035):**
```sql
from box.all.win
select target_username as evTargetUserName
select target_domain as evTargetDomainName, subject_username as evSubjectUserName
where 
    type = "security",
    eventID = 4723 or eventID = 4724,
    audit_result = "Success",
    not(endswith(evSubjectUserName, "$") 
        or eqic(evSubjectUserName, "svc_cyberarkrecon")
        or eqic(evSubjectUserName, "svc_iamsp")),
    not(endswith(evTargetUserName, "$"))
group every - by evTargetUserName, evTargetDomainName
select count() as count where count >= 3
```

**Alert 2 — Multiple Failed Password Attempts (Brute Force):**
```sql
from box.all.win
select target_username as evTargetUserName
select target_domain as evTargetDomainName, subject_username as evSubjectUserName
where 
    type = "security",
    eventID = 4723 or eventID = 4724,
    audit_result = "Failure",
    not(endswith(evSubjectUserName, "$") 
        or eqic(evSubjectUserName, "svc_cyberarkrecon")
        or eqic(evSubjectUserName, "svc_iamsp")),
    not(endswith(evTargetUserName, "$"))
group every 1h by evTargetUserName, evTargetDomainName
select count() as count where count >= 10
```

**Why two alerts:** Success = account takeover (investigate, hours response time); Failure = active attack (block immediately, minutes response time). Combining them loses threat intelligence and forces same-threshold noise.

**Machine/service account exclusions are critical** — without them, automated rotations and service accounts drown alerts in false positives.

---

## XSOAR Integration — Anti-Flooding & Period Staggering

**Root cause (ISM-15655 — Curo XSOAR duplicates):** When multiple alerts share an exact round period (e.g., 4h, 1h), they fire simultaneously. XSOAR truncates milliseconds from timestamps during fetch — so an alert at `2:00:00.123` becomes `2:00:00.000`. On the next fetch cycle, XSOAR re-queries from that second and pulls the same alert again → duplicates.

**Fix:** Change the period to a non-round number so the alert drifts away from collision times.

```bash
# Step 1: Check current period
source ~/.zshrc && sql usa_pro -e "
SELECT
    alert_context_subscription.id,
    alert_context.name,
    JSON_EXTRACT(params, '\$.object.period') as current_period_ms,
    ROUND(JSON_EXTRACT(params, '\$.object.period') / 60000, 2) as current_period_minutes
FROM alert_context
JOIN alert_context_subscription ON alert_context.id = alert_context_subscription.alert_context_id
WHERE alert_context.name = 'my.alert.curo.MS_Graph_Inactivity_Alert';
"

# Step 2: Update to non-round period (4h → 3h 59m 30s = 14370000ms)
source ~/.zshrc && sql usa_pro -e "
UPDATE alert_context_subscription
SET params = JSON_SET(params, '\$.object.period', 14370000)
WHERE id = 294186;
"

# Step 3: Verify
source ~/.zshrc && sql usa_pro -e "
SELECT
    alert_context.name,
    JSON_EXTRACT(params, '\$.object.period') as new_period_ms,
    ROUND(JSON_EXTRACT(params, '\$.object.period') / 3600000, 4) as new_period_hours
FROM alert_context
JOIN alert_context_subscription ON alert_context.id = alert_context_subscription.alert_context_id
WHERE alert_context.name = 'my.alert.curo.MS_Graph_Inactivity_Alert';
"
```

**Stagger patterns:**

| Original Period | Stagger Offset | New Period (ms) | New Period |
|-----------------|----------------|-----------------|------------|
| 4h (14400000) | -30s | 14370000 | 3h 59m 30s |
| 1h (3600000) | -3m 45s | 3375000 | 56m 15s |
| 8h (28800000) | -2h | 21600000 | 6h 0m 0s |

**Stagger multiple 1-hour alerts** (distribute 16 alerts across the hour, interval = 225000ms = 3m 45s):
```sql
UPDATE alert_context_subscription SET params = JSON_SET(params, '$.object.period', 3600000) WHERE id = 271218;  -- 60m 0s
UPDATE alert_context_subscription SET params = JSON_SET(params, '$.object.period', 3375000) WHERE id = 269622;  -- 56m 15s
UPDATE alert_context_subscription SET params = JSON_SET(params, '$.object.period', 3150000) WHERE id = 352308;  -- 52m 30s
-- ... continue for remaining alerts
```

**Find collision groups:**
```bash
source ~/.zshrc && sql usa_pro -e "
SELECT
    JSON_EXTRACT(params, '\$.object.period') / 3600000 as period_hours,
    COUNT(*) as alert_count,
    GROUP_CONCAT(alert_context.name SEPARATOR ', ') as alert_names
FROM alert_context
JOIN alert_context_subscription ON alert_context.id = alert_context_subscription.alert_context_id
WHERE alert_context.name LIKE 'my.alert.curo%'
  AND JSON_EXTRACT(params, '\$.object.period') > 0
GROUP BY period_hours
HAVING alert_count > 1
ORDER BY period_hours;
"
```

**Anti-flooding monitoring:**
```bash
source ~/.zshrc && maquius "from alert.error where client = 'curo' and now() - 7d <= eventdate and type = 'ANTI_FLOODING' group by alert_name select count() as suppressed_alerts"
```

**XSOAR notes (ISM-15655):**
- Customer: Talion / Curo (AWS US, domain: `curo`)
- Affected alert: `my.alert.curo.MS_Graph_Inactivity_Alert` (subscription ID: 294186)
- Period changed: 14400000ms (4h) → 14370000ms (3h 59m 30s)
- Immediate workaround: "Reset the 'last run' timestamp" in XSOAR integration config
- XSOAR timestamp truncation bug is an integration-layer issue; period staggering is the operational fix

---

## Cross-Domain Injection Failures — Silent "Alive" Pattern

**Reference case:** ISM-16741 — Cybergenics APAC, `slith@gable` → `gsoc@gable` injection

**Symptom:** Injection shows status `alive` in Malote logs, no `errorMessage`, no `errorCode`, data simply stops arriving in target domain silently.

**Two failure modes that produce zero errors:**

**1. Hardcoded `le(timestamp(...))` upper bound:**
```sql
-- BROKEN: static ceiling, stops matching after the fixed date
where le(timestamp(1778068388901), eventdate)

-- FIXED: rolling 1h lookback, always matches recent events
where ge(now() - 1h, eventdate)
```

**2. Revoked relay certificate blocking TLS writes via Batrasio:**
`CN="su@gable", issuerCA=userAWSAPACCA` — Batrasio rejects every write at TLS auth. Malote reads succeed (no error) but writes never land.

### Diagnosis Queries

```bash
# 1. Confirm data stopped flowing into target (find exact cutoff)
source ~/.zshrc && maquiapac "from my.app.\`gsoc@gable\`.slith.alert where client = \"gsoc@gable\" where now() - 30d <= eventdate group every 1d select count() as records, eventdate"

# 2. Confirm source is healthy
source ~/.zshrc && maquiapac "from siem.logtrust.alert.info where client = \"slith@gable\" where now() - 7d <= eventdate group every 1d select count() as daily_alerts, eventdate"

# 3. Extract actual reinjection query from Malote logs (look for le() ceiling)
source ~/.zshrc && maquiapac "from siem.logtrust.malote.query where client = \"self\" where now() - 24h <= eventdate where has(raw, \"reinjection\") where has(raw, \"slith\") select eventdate, raw limit 5"

# 4. Check Batrasio for revoked cert errors
source ~/.zshrc && maquiapac "from siem.logtrust.batrasio.free where client = \"self\" where now() - 7d <= eventdate where has(message, \"Revoked\") or has(message, \"revoked\") select eventdate, message, instance limit 20"
```

### Fix Checklist

- [ ] **Cert fix (if revoked):** Re-issue relay cert under regional CA, update on relay host
- [ ] **Query fix:** Delete + recreate injection with rolling window (`ge(now() - 1h, eventdate)`)
- [ ] **Verify:** `count() > 0` in target table within 10 min of fix

### MySQL Injection Table (APAC)

```sql
SELECT id, name, status, sourceTable, targetDomain, tableName,
       period, gid, qid, creation_date, last_update
FROM injection
WHERE queryDomain = 'slith@gable';
```

Key fields: `gid` + `qid` identify the Laszlo grain. `period = 0` = event-driven.

### Verification After Fix

```bash
source ~/.zshrc && maquiapac "from my.app.\`gsoc@gable\`.slith.alert where client = \"gsoc@gable\" where now() - 2h <= eventdate select count() as records"
```

---

## TAPU — Token Manager Service

**Reference case:** ISM-16519 — Talion/ucl domain, missing `_z` tokens

TAPU is Devo's internal OAuth2-based token authentication service and the authoritative backend for the Tokens Management UI.

- **Code:** TPU | **Language:** Java (JDK 17), embedded Jetty | **Framework:** Jenga
- **Owner:** Backstage / General Services squad
- **K8 namespace:** `devo-prod-eu-core` (EU), `devo-prod-us-core` (US), etc.
- **Backing store:** MySQL `logtrust` database (same RDS as rest of platform)

### access_token Table Schema

```sql
DESCRIBE access_token;
-- id, token, refresh_token, type, name, scope, user_domain (FK→user_domain.id),
-- owner (FK→user_domain.id), expires_in, refresh_expires_in, update_date,
-- creation_date, audience, domain, status, auto_refresh, session_id, extra
```

- `status = 1` → active/enabled; `status = 0` → disabled/revoked
- `expires_in`: seconds; `-1` = never expires
- Token types: `Bearer` (API), `Session` (web login), `Service` (internal)

### Nightly Auto-Delete (Critical!)

```properties
# /opt/tapu/conf/tapu.properties
tapu.scheduler.task.deleteExpired.cron = 0 0 5 * * *
```

**TAPU hard-deletes expired tokens every day at 05:00 UTC.** No soft-delete, no archive table, no audit trail, no recovery. Once expired + cron runs → **permanently gone**.

### Querying TAPU Logs

Correct log table: `siem.logtrust.tapu.service` (NOT legacy `web.tomcat.out where application = "tapu-logtrust"`)
Token references in logs: `tk.{last5chars}.{md5hash}` — never full token value.

```bash
# Find token creation events for a domain
source ~/.zshrc && maquieu 'from siem.logtrust.tapu.service where operation = "requestAccessToken" and message ~ "domain=ucl" and eventdate >= "2026-01-01 00:00:00" and eventdate <= "2026-05-15 23:59:59" select eventdate, operation, entity, auth, id, message limit 200' 2>&1

# Find specific token name in creation log
source ~/.zshrc && maquieu 'from siem.logtrust.tapu.service where message ~ "Wolfhound" and eventdate >= "2026-01-01 00:00:00" and eventdate <= "2026-05-15 23:59:59" select eventdate, operation, entity, auth, id, message limit 100' 2>&1

# Find delete/disable operations
source ~/.zshrc && maquieu 'from siem.logtrust.tapu.service where (message ~ "delete" or message ~ "disable" or message ~ "revoke") and eventdate >= "2026-05-01 00:00:00" and eventdate <= "2026-05-15 23:59:59" select eventdate, operation, message limit 50' 2>&1
```

### Querying MySQL for Token Details

```bash
# List all tokens for a domain
source ~/.zshrc && sql eu_pro -e "
SELECT at.id, at.name, at.type, at.status, at.creation_date, at.update_date, at.expires_in, at.user_domain as ud_id
FROM access_token at
JOIN user_domain ud ON ud.id = at.user_domain
JOIN domain d ON d.id = ud.domain_id
WHERE d.name = 'ucl'
ORDER BY at.creation_date DESC
LIMIT 30;" 2>&1

# Find tokens by name pattern
source ~/.zshrc && sql eu_pro -e "SELECT id, name, type, status, creation_date, update_date, expires_in, user_domain FROM access_token WHERE name LIKE '%Fluentbit%' ORDER BY creation_date;" 2>&1

# Find user email behind a user_domain id
source ~/.zshrc && sql eu_pro -e "
SELECT ud.id, u.email, d.name as domain_name, ud.owner
FROM user_domain ud
JOIN user u ON u.id = ud.user_id
JOIN domain d ON d.id = ud.domain_id
WHERE ud.id = 137076;" 2>&1
```

### K8 Pod Operations

```bash
source ~/.zshrc && kube get pods -n devo-prod-eu-core 2>&1 | grep tapu
source ~/.zshrc && kube exec -n devo-prod-eu-core <tapu-pod> -- cat /opt/tapu/conf/tapu.properties 2>&1
source ~/.zshrc && kube logs <tapu-pod> -n devo-prod-eu-core --tail=200 2>&1 | grep -iE "(ERROR|WARN|Exception)"
# Health check: https://<tapu-svc>/tapu/system/healthcheck?pretty=true
```

### Troubleshooting Token Issues

| Symptom | Check | Fix |
|---------|-------|-----|
| Token missing from UI | Check `access_token` by `name LIKE '%..%'` | If expired + past 05:00 UTC, deleted by cron. Recreate with `expires_in = -1`. |
| Token shown as "Disabled" | Check `status` and `expires_in + creation_date` | Expired token awaiting cron deletion OR manually disabled |
| UI shows token but MySQL doesn't | TAPU cache (60s, max 5000 entries) | Wait 60s or check `tapu.cache.evictInSeconds` |
| Token creation fails | Check `siem.logtrust.tapu.service` logs | Check auth, domain permissions, scope validity |

**Key conclusion for customers:** There is no audit trail for TAPU token deletions. Expired tokens are permanently purged at 05:00 UTC daily. Set `expires_in = -1` for tokens that must persist.

**Token lifecycle (DRD BAC-3112):** User deactivated → tokens deactivated (status=0); user deleted → tokens permanently deleted.

---

## Pilot / pirulo — Alert Context Operations on Node

pirulo is the Pilot REPL — used for direct alert context management on the Pilot host (legacy non-K8s deployments, or when K8s pod operations are not sufficient).

**Pilot hosts:**
- US: `pil01-pro-general-us-aws` — heap: 31G, RAM: 62G
- EU (non-K8s, dedicated VMs):
  - `pil01-pro-general-eu-aws` (172.17.1.215) — general domains — heap: 10G, RAM: 15G
  - `pil02-pro-custom-eu-aws` (172.17.1.152) — custom/dedicated domains — heap: 10G, RAM: 30G
- GCP-TEF (non-K8s, dedicated VM):
  - `pilot-custom-1-pro-cloud-tef-gcp-europe-west1` (10.6.3.238) — heap: 31G (CHG-10671), RAM: 62G
  - Ansible group_vars: `ansible/environments/gcp/eu/tef/group_vars/pilot.yml`
  - Context files: `/etc/logtrust/pilot/contexts/` (2,551 files, `640 logtrust:logtrust`)
  - Scripts: `/etc/logtrust/pilot/scripts/`
  - JVM options: `/opt/logtrust/pilot/etc/pilot.javaoptions`
  - Recovery lookback: `P2D` (2 days) via `injection_lookback_period` in `pilot_env.sh`; default fallback = 10 days

### EU Pilot Heap Leak — ISM-16483

**Symptom:** Massive `CANCELED-pilot-server` spikes in `siem.logtrust.malote.query` (20k+/min). Malote query errors by errorKind chart shows dominant orange `CANCELED-pilot-server` wave repeating every ~15 min.

**Root cause:** Pilot process runs for months without restart → Groovy closures + query result objects accumulate in heap and are never GC'd. Each alert evaluation leaks `MethodClosure`, `HardRef`, `Timestamp`, `Long` objects.

**Diagnose with jmap (run directly on server as logtrust):**
```bash
# Get pilot PID
pgrep -f pilot

# Heap histogram — look for millions of MethodClosure / Timestamp / String
jmap -histo <pid> | head -30
```

**Leak indicators (unhealthy):**

| Class | Healthy | Leaked |
|---|---|---|
| `java.lang.String` | ~178K | 8M–20M+ |
| `java.sql.Timestamp` | 0 | 1.4M–3M+ |
| `MethodClosure` | 0 | 600K–1.4M+ |
| `HardRef` | 0 | 600K–1.4M+ |
| Tasks/threads | ~105 | 1,600+ |
| Memory used | ~31 MB | 10+ GB |

**pil02 was leaking (2y3m uptime, never restarted). pil01 was clean (restarted Oct 2024).**

**Fix — restart pilot service (requires confirmation):**
```bash
systemctl stop pilot.service
systemctl daemon-reload
systemctl start pilot.service
```

**Verify improvement:**
```bash
# CANCELED should drop from 20k/min → <300/min after restart
maq eu 'from siem.logtrust.malote.query where client = "self" and now()-5m <= eventdate < now() and isnotnull(errorKind) group every 1m by errorKind select count() as cnt'
```

**Note:** Restart clears the leak but it will return over time. Permanent fix requires pilot-server code fix (ISM-14287 — unclosed query objects in Groovy alert evaluation). Schedule periodic restarts until code fix is deployed.

**Check open connections from pilot to malote:**
```bash
ss -tnp | grep '10100\|10112\|10113\|10114' | wc -l
# Healthy: <100. Leaked: 400-500+
```

### Connect to pirulo

```bash
# Direct on host
echo "pilot" | /opt/logtrust/pilot/bin/pirulo

# Via kubectl (K8s-deployed)
kubectl exec -it pod/pilot-0 -n devo-prod-ncscbh-core -- bash
```

### Restart a Single Alert Context

```bash
# Stop → clear → remove → reload → start
echo 'pilot."my.alert.curo.ALERT_NAME_".stop()' | /opt/logtrust/pilot/bin/pirulo
echo 'pilot."my.alert.curo.ALERT_NAME_".clear()' | /opt/logtrust/pilot/bin/pirulo
echo 'pilot."my.alert.curo.ALERT_NAME_".remove()' | /opt/logtrust/pilot/bin/pirulo
echo 'pilot.load("/opt/pilot/contexts/my.alert.curo.ALERT_NAME_.pilot")' | /opt/logtrust/pilot/bin/pirulo
echo 'pilot."my.alert.curo.ALERT_NAME_".start(true)' | /opt/logtrust/pilot/bin/pirulo
```

**Real example (Curo SUC70035):**
```bash
echo 'pilot."my.alert.curo.SUC70035_Alert_for_Multiple_Password_Changes_for_Account_1Day_".stop()' | /opt/logtrust/pilot/bin/pirulo
echo 'pilot."my.alert.curo.SUC70035_Alert_for_Multiple_Password_Changes_for_Account_1Day_".clear()' | /opt/logtrust/pilot/bin/pirulo
echo 'pilot."my.alert.curo.SUC70035_Alert_for_Multiple_Password_Changes_for_Account_1Day_".remove()' | /opt/logtrust/pilot/bin/pirulo
echo 'pilot.load("/opt/pilot/contexts/my.alert.curo.SUC70035_Alert_for_Multiple_Password_Changes_for_Account_1Day_.pilot")' | /opt/logtrust/pilot/bin/pirulo
echo 'pilot."my.alert.curo.SUC70035_Alert_for_Multiple_Password_Changes_for_Account_1Day_".start(true)' | /opt/logtrust/pilot/bin/pirulo
```

### Manage alertDispatch and myappGenerator

```bash
# Stop alertDispatch (pauses ALL alert delivery — reload immediately after)
echo 'pilot."alertDispatch".stop()' | /opt/logtrust/pilot/bin/pirulo
echo 'pilot."alertDispatch".clear()' | /opt/logtrust/pilot/bin/pirulo
echo 'pilot."alertDispatch".remove()' | /opt/logtrust/pilot/bin/pirulo
# Delete context file only if permanently removing
# /etc/logtrust/pilot/contexts/alertDispatch.pilot

# Stop myappGenerator
echo 'pilot."myappGenerator".stop()' | /opt/logtrust/pilot/bin/pirulo

# Reload context file manually
pilot.load "/etc/logtrust/pilot/contexts/myappGenerator.pilot"
```

### Context Files

Located at `/etc/logtrust/pilot/contexts/` on the Pilot host.
Each `.pilot` file corresponds to one alert context. Filename = context name.

**⚠️ Removing `alertDispatch.pilot` stops all alert delivery — only delete deliberately.**

---

## Flow Contexts (myappGenerator / Ingestion Stats) — K8s pilotserver-customers

Flow contexts (non-alert Flows writing to `my.app.*` tables) run in **`pilotserver-customers`** StatefulSet, not `pilotserver-alerts`. The `pilot-0` pod hosts the pirulo REPL for this cluster.

**Key distinction:**
| StatefulSet | Handles | Namespace |
|---|---|---|
| `pilotserver-alerts` | Alert Flows (`siem.logtrust.alert.info`) | `devo-prod-*-core` |
| `pilotserver-customers` | Data Flows writing `my.app.*` tables | `devo-prod-*-core` |
| `pilot-0` | Legacy alert contexts + pirulo REPL | `devo-prod-*-core` |

### Flow Context DB (pilot schema)

Flow contexts are stored in the **`pilot`** schema on RDS (separate from `logtrust`):
- **US3:** `prod-us3.cluster-czlrtg0lyu3i.us-east-2.rds.amazonaws.com:3306/pilot`
- **Credentials:** user=`pilot`, password from `/vault/secrets/secure.properties` (`lt.pilot.std.db.EternalQueryReader.conf.database.password` is dummy — use `pilot.jdbc.password`)

**Tables in pilot schema:** `contexts`, `templates`, `credentials`, `applications`, `DATABASECHANGELOG`

**`contexts` table columns:** `id` (binary16), `name`, `user_id`, `domain_id`, `server_model` (JSON — the full Flow script), `client_model`, `running`, `loaded`, `server_id`, `creation_date`, `update_date`, `template_id`, `params`, `application_id`, `application_key`

**`server_model`** contains the full Flow DSL as JSON: units array (DevoSource, DevoSink), links array, computed props.

### Query Flow Script via pirulo

```bash
# Connect to pilot-0, use pirulo + Groovy SQL to read pilot DB directly
source ~/.zshrc && kube exec -n devo-prod-us3-core pilot-0 -- /opt/pilot/bin/pirulo -e "
import groovy.sql.Sql
def sql = Sql.newInstance('jdbc:mysql://<rds-host>:3306/pilot?autoReconnect=true&enabledTLSProtocols=TLSv1.2&useSSL=true', 'pilot', '<password>', 'com.mysql.cj.jdbc.Driver')
def rows = sql.rows('SELECT name, running, server_model FROM contexts WHERE id = UUID_TO_BIN(?)', ['<uuid>'])
rows.each { row -> println('NAME: ' + row.name); println('RUNNING: ' + row.running); println(row.server_model) }
sql.close()
" 2>&1 | grep -v 'Accessing\|Creating\|Evaluating\|WARNING\|deprecated\|unnecessary'
```

**⚠️ Note:** The `pilot.contexts.id` is `binary(16)` — use `UUID_TO_BIN(?)` not `= ?` directly.

### Flow Context Startup Failure — `UnitConfigException: Illegal value at 'query'`

**Reference case:** ISM-16763 — `vivo_us_ar@ds`, context `Ingestion Stats` (UUID `09fb4c8a-9ea9-4151-a8f6-a33af6029b2d`), US3

**Error:**
```
pilot.error.UnitConfigException: Unit 'GeneralStats_3_levels':
Illegal value at 'query': General error
```

**Root cause:** A DevoSource unit's LINQ query references a field (`phylum`) that is `null` for some matching rows, causing string concatenation to produce an illegal value. Example — `vmware` rows have no `phylum`, so `technology + "." + brand + "." + phylum` → invalid.

**Fix:** Replace bare concatenation with `ifthenelse` null guard (same pattern used in `GeneralStats_AllData` unit):
```sql
-- BROKEN
technology + "." + brand + "." + phylum as tech

-- FIXED
ifthenelse(
    isnull(phylum) or isempty(phylum),
    technology + "." + brand,
    technology + "." + brand + "." + phylum
) as tech
```

**This is a customer-side fix** — the Flow belongs to the customer's domain user. They must edit the Flow in Cockpit UI → fix the query in the failing unit → save → start.

### Cockpit Flow Status — Stale UI

**Symptom:** Cockpit shows "Running" but pod logs show context was stopped.

**Cause:** Cockpit reads status from its own DB (`logtrust.alert_context_subscription`) which may lag behind pilot's runtime state.

**Verify actual state:**
```bash
# Check last event in pilotserver-customers logs for the context UUID
source ~/.zshrc && kube logs -n devo-prod-us3-core pilotserver-customers-0 --since=1h 2>&1 | grep -i "<uuid>" | tail -10
```

**The `⏸` pause button in Cockpit = STOP** — clicking it when status appears "Running" will stop the context, not pause it. The "Success" toast confirms the action taken (stop), not that the context is now running.

### pilotserver-customers Internal API

The pilotserver HTTP API requires auth (TAPU token). Cannot call it unauthenticated from inside the pod:
```bash
# This will 401
kube exec -n devo-prod-us3-core pilotserver-customers-0 -- curl -X PUT http://localhost:8080/internal/contexts/<uuid>/start
```

**Start/stop must be done via Cockpit UI** (uses browser session token) or via the Cockpit REST API with a valid domain token.

---

## Related Skills

- **/devo-database** — MySQL direct access, Adolfo for datanode management
- **/devo-query** — Complete Maqui query system with 97 functions
- **/devo-infra** — Kubernetes cluster access across regions
- **/devo-jira** — Jira issue tracking and Confluence documentation
