# Customer Offboarding Automation

Automated offboarding operations for Devo customer domains across all regions (EU, US, APAC, SANT).

**Status:** ✅ Phase 1 Complete — Admin User Creation via Probio API (all regions working)  
**CHG:** [CHG-10630](https://devoinc.atlassian.net/browse/CHG-10630) — In Progress (assigned: Vikash Jaiswal)

---

## Reseller vs Domain Customers (CRITICAL)

| Type | Description | Example |
|------|-------------|---------|
| **Reseller** | Parent entity with multiple sub-domains | `corsica` → owns ~20 sub-domains like `banks_technologies@corsica` |
| **Domain** | Single standalone customer domain | `secops_101` |

Sub-domains under a reseller follow the pattern: `<subdomain_name>@<reseller_name>`

### Key DB Relationships

```sql
-- Find sub-domains for a reseller
SELECT domain.name, api_key, api_secret
FROM credentials
JOIN domain ON domain_id = domain.id
WHERE domain.name LIKE '%@corsica'
  AND credentials.status = 0;
```

- `credentials.status = 0` → active credentials
- Each domain has its own `api_key` + `api_secret` in the `credentials` table
- For resellers: each sub-domain has its OWN separate credentials row
- **Reseller-level key** (for NASS auth) comes from NASS "Config Resellers" page — NOT the DB
- **Why NASS, not DB:** The DB `credentials` table contains per-domain keys only. Using a sub-domain DB key to authenticate as the reseller fails silently or returns wrong results. The reseller key is only shown in NASS.
- **Sub-domain enumeration:** `SELECT DISTINCT domain.name FROM domain WHERE domain.name LIKE '%@<reseller>' ORDER BY domain.name`

---

## Phase 1: Admin User Creation via Probio API

- **DOMAIN type**: credentials fetched from DB `credentials` table
- **RESELLER type**: credentials from NASS "Config Resellers" page; user created in each sub-domain

### Probio API Endpoints

| Region | Public URL | Notes |
|--------|-----------|-------|
| EU | `https://api-internal-eu.devo.com/probio` | ✅ Internal — bypasses Cloudflare |
| US | `https://api-internal-us.devo.com/probio` | ✅ Internal — bypasses Cloudflare |
| APAC | `https://api-internal-apac.devo.com/probio` | Internal — untested but should work |
| SANT | `http://api-internal.san.devo.com/probio` | Internal |

**Public URLs (do NOT use from Jenkins):**
`api-eu.devo.com`, `api-us.devo.com` etc. go through Cloudflare — Jenkins (AWS eu-west-1) always geo-routes to EU PoP → 404 for non-EU domains.

### API Call

```
POST {probio_url}/user/internal?skipMailValidation=false
```

**Headers:**
```
Content-Type: application/json
x-logtrust-apikey:    <api_key>
x-logtrust-sign:      <HMAC-SHA256 signature>
x-logtrust-timestamp: <epoch ms>
```

**Body (key order matters):**
```json
{
  "email":    "engineer@devo.com",
  "domain":   "banks_technologies@corsica",
  "role":     "admin",
  "userName": "engineer.name"
}
```

### HMAC-SHA256 Signing

```python
import hmac, hashlib, json, time

body          = json.dumps(user_payload, separators=(',', ':'))
timestamp     = str(int(time.time() * 1000))
text_to_sign  = api_key + body + timestamp
signature     = hmac.new(
    api_secret.encode('utf-8'),
    text_to_sign.encode('utf-8'),
    hashlib.sha256
).hexdigest()
```

**Critical:**
- Key order in body JSON must be: `email`, `domain`, `role`, `userName`
- Pass credentials via `withEnv` in Groovy — NOT string interpolation (special chars in secret break signing)
- Devo returns **404** (not 401) for invalid/mismatched signatures — misleading error

### Corsica Reseller Credentials (US)

- **Source:** NASS US → `nass-us.devo.com/confRes` → Config Resellers → corsica → General tab
- **API Key:** `7Kp1HcOvfAXafLdLMfaN5Y1anzXrKtkLU8eipjG6kagnBxMejO` (len=50)
- **API Secret:** `1pmx4pr2ixAxUaH1N1BporvyqhlWjKvLQE32ao901oL2SaMk0sPIMvLpMqnLroVM` (len=64)
- Note: secret contains `sPIMvLp` (capital I) — easy to confuse with lowercase `l`

---

## DB Credential Fetch

```sql
SELECT domain.name, api_key, api_secret
FROM credentials
JOIN domain ON domain_id = domain.id
WHERE domain.name LIKE '%<customer_pattern>%'
  AND credentials.status = 0
LIMIT 2;
```

### DB Access via ~/.adolfo.yaml

```bash
DB_HOST=$(grep -A 5 "^eu_pro:" ~/.adolfo.yaml | grep "host:" | awk '{print $2}' | tr -d "'")
DB_USER=$(grep -A 5 "^eu_pro:" ~/.adolfo.yaml | grep "user:" | awk '{print $2}' | tr -d "'")
DB_PASS=$(grep -A 5 "^eu_pro:" ~/.adolfo.yaml | grep "password:" | awk '{print $2}' | tr -d "'")
```

### DB Environment Mapping

| Region | DB_ENV |
|--------|--------|
| EU | `eu_pro` |
| US | `usa_pro` |
| APAC | `ap_pro` |
| SANT | `santander_eu` |

---

## Jenkins Pipeline

**File:** `jenkinsfiles/jobs/job_ops_create_admin_user_probio.groovy`
**Jenkins job:** `https://devo-devtool.devotools.com/job/RaD-Deployments/job/create_admin_user_probio/`

### Parameters

| Parameter | Description |
|-----------|-------------|
| `REGION` | EU / US / APAC / SANT |
| `CUSTOMER_TYPE` | `DOMAIN` (creds from DB) or `RESELLER` (creds from NASS) |
| `CUSTOMER_NAME` | Domain name or reseller alias (e.g. `corsica`) |
| `RESELLER_API_KEY` | NASS API key (RESELLER only) |
| `RESELLER_API_SECRET` | NASS API secret (RESELLER only) |
| `TARGET_DOMAIN` | Specific sub-domain to target (RESELLER only, leave empty for all) |
| `USER_EMAIL` | Engineer email to create as admin |
| `USER_NAME` | Login username |
| `USER_ROLE` | `admin` or `user` |
| `DRY_RUN` | Default `true` — preview only, no API call |
| `SKIP_APPROVAL` | Default `false` — requires human approval |
| `PROBIO_URL_OVERRIDE` | Override base URL (use for direct/internal endpoints) |

### Pipeline Stages

```
1. Validate Parameters
   → email format, required fields, region → URL + DB_ENV mapping

2a. Fetch Domain Credentials (DB)   [DOMAIN type only]
   → SQL query via ~/.adolfo.yaml

2b. Enumerate Reseller Sub-Domains (DB)   [RESELLER type only]
   → Uses NASS key directly
   → If TARGET_DOMAIN set: use it; else enumerate all %@<reseller> from DB

3. Preview Request
   → Shows endpoint, body, target domains

4. Manual Approval   [skipped if DRY_RUN=true or SKIP_APPROVAL=true]
   → Human confirms before API call

5. Create Admin User (Probio API)   [skipped if DRY_RUN=true]
   → Python script via withEnv (credentials passed as env vars, not string interpolation)
   → Exit 0=success, 3=already exists (skipped), 1/2=failure
   → Reports succeeded/skipped/failed per domain
```

### Probio Success Response Format

Probio returns a **user object** on success (HTTP 200), NOT `{"code": 0}`:
```json
{"email":"vikash.jaiswal@devo.com","userName":"Vikash Jaiswal","role":"ADMIN","domain":"choctaw_global@corsica","owner":false,"status":"pending","roleList":["ADMIN"]}
```
Success detection: `HTTP 200 AND 'email' in response AND 'error' not in response`

Error response format: `{"error": {"code": 100, "message": "..."}}`
Already-exists: HTTP 400 with `"already exists"` in message → exit code 3 (skipped, not failed)

### Key Groovy Fixes Applied

- **No `environment {}` block** — it locks `env.*` vars to empty string, overriding assignments in `script {}` blocks
- **Local `def` vars before loop** — `env.*` can be null inside nested closures; capture to local vars first
- **`withEnv` for Python** — use `withEnv([...]) { sh ... }` not `sh(environment: [...])` (latter not supported)
- **Credentials via env vars** — avoids Groovy string interpolation breaking HMAC when secret has special chars

---

## Cloudflare WAF Setup

Jenkins IP `176.34.163.105` added to Cloudflare:

1. **`$devo` IP list** — `176.34.163.105` with comment "Devo-Jenkins"
2. **Custom rule "Allow Jenkins Server"** — Order 1, expression `(ip.src in $devo)`, action `Skip`
   - Skips: All remaining custom rules, rate limiting, managed rules, Super Bot Fight Mode, Browser Integrity Check, Security Level

**Note:** Despite the CF bypass, US traffic still geo-routes to EU PoP from Jenkins (AWS eu-west-1). Use internal URLs.

---

## Datanode Decommission — Disable RDS installation Entries

After customer data is offboarded, their datanode/metamalote/alcohol entries must be disabled in the shared RDS `installation` table. If skipped, all EU metamalotes keep connecting to dead IPs → Chasys `droppedDatanodesDetector` unknown alerts every ~15 min.

```bash
# Check what's still enabled
source ~/.zshrc && sql eu_pro -e "SELECT type, COUNT(*), SUM(IF(enabled=1,1,0)) as enabled FROM installation WHERE name LIKE '%<customer>%' GROUP BY type;"

# Disable all entries
source ~/.zshrc && sql eu_pro -e "UPDATE installation SET enabled = 0 WHERE name LIKE '%<customer>%';"

# Restart all 10 EU general metamalotes
for i in 1 2 3 4 5 6 7 8 9 10; do
  ssh metamalote-${i}-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && systemctl is-active metamalote"
done
```

**Note:** Do NOT edit metamalote conf files or `--delegate-tags` — the `installation` table (RDS) is the single source of truth for the delegation tree. Metamalote restart is required to flush cached state.

**Precedent:** Deloitte CHG-10524 (2026-05-04) — 86 rows (2 metamalote + 68 datamalote + 16 alcohol).

---

## Planned Phases

| Phase | Scope | Status |
|-------|-------|--------|
| **Phase 1** | Admin user creation via Probio API | ✅ Complete |
| Phase 2 | Table creation | ⏳ Pending |
| Phase 3 | Domain creation | ⏳ Pending |
| Phase 4 | Update retention | ⏳ Pending |
| Phase 5 | Alert creation | ⏳ Pending |
| Phase 6 | Database user creation | ⏳ Pending |
| **Decommission** | Disable RDS installation entries + restart metamalotes | ✅ Documented |

---

## Related Skills

- `/devo-database` — MySQL access via Adolfo, DB schema reference
- `/devo-devtool` — Jenkins job management
- `/devo-jira` — Read Jira tickets for offboarding context (READ ONLY)

## Related Files

- `jenkinsfiles/jobs/job_ops_create_admin_user_probio.groovy` — Phase 1 Jenkins pipeline
