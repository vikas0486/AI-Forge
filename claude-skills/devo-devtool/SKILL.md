---
name: devo-devtool
description: Developer tooling — Jenkins CI/CD (builds, deployments, disk management), GitLab pipeline fixes (auth, loops, Vault migration), and Monitoring (Grafana, Prometheus, Alertmanager silences across all prod clusters).
argument-hint: "[jenkins|gitlab|monitoring] [issue]"
tags: [jenkins, gitlab, cicd, grafana, prometheus, alertmanager, monitoring, pipelines]
---

## Skill Boundaries

| What | Section |
|------|---------|
| Jenkins build/deploy/troubleshoot | **Jenkins** |
| GitLab CI/CD pipeline failures | **GitLab Pipelines** |
| Grafana, Prometheus, Alertmanager silences | **Monitoring** |

---

## ⛔ CRITICAL — Never Use `find` on Datanodes

**NEVER run `find /var/logt ...` or any recursive file search on datanode hosts.**  
Datanodes store TBs of data across deep directory trees. A `find` command will run for hours, peg I/O, and impact live query performance.

**Use instead:**
- Maqui queries (`system.delegated.internal.tableFile`, `system.delegated.internal.table`) to locate aggr files — these are indexed
- `ls` on a known specific path if you have the exact trunk/bucket/date
- Asilo commander `status` to understand what partition slots Asilo thinks exist

---

## Jenkins

**Instance:** https://jenkins.devotools.com  
**Server:** `jenkins-2-devtools-cloud-shared-aws-eu-west-1` (10.255.1.198, i-00544c45d9146781f)  
**Specs:** Ubuntu 20.04, Jenkins 2.492.1, OpenJDK 17, 24 executors, 33 GB RAM, 600 GB disk at `/var/lib/jenkins`  
**Credentials:** `~/.devo/credentials` (JENKINS_URL, JENKINS_USER, JENKINS_API_TOKEN)  
**Wrapper:** `~/Documents/Scripts/jenkins-wrapper.sh` | **Alias:** `jenkins`

**SSH / SSM access:**
```bash
ssh 10.255.1.198
aws ssm start-session --target i-00544c45d9146781f
```

### Authentication

API token authentication only — no Cloudflare cookie required.  
Credentials in `~/.devo/credentials`: `JENKINS_URL`, `JENKINS_USER`, `JENKINS_API_TOKEN`

**Check connection:**
```bash
source ~/.zshrc && jenkins status
```

### Quick Start

```bash
# Test connection
source ~/.zshrc && jenkins status

# Search for jobs
source ~/.zshrc && jenkins search metamalote

# Job summary
source ~/.zshrc && jenkins job RaD-Deployments/aws-eu-pro/metamalote

# Recent builds
source ~/.zshrc && jenkins builds RaD-Deployments/aws-eu-pro/metamalote 5

# Build summary
source ~/.zshrc && jenkins build RaD-Deployments/aws-eu-pro/metamalote 132

# Console output
source ~/.zshrc && jenkins console RaD-Deployments/aws-eu-pro/metamalote 132 50

# Trigger build
source ~/.zshrc && jenkins trigger RaD-Deployments/aws-eu-pro/metamalote SERVICE=metamalote TARGET=datanode-1

# Build parameters
source ~/.zshrc && jenkins params RaD-Deployments/aws-eu-pro/metamalote 132
```

### Alias Subcommands Reference

| Subcommand | Usage |
|---|---|
| `jenkins status` | Test connection |
| `jenkins jobs [filter]` | List all jobs |
| `jenkins job JOB/PATH` | Formatted job summary |
| `jenkins search term` | Search jobs by name |
| `jenkins builds JOB/PATH [limit]` | List recent builds |
| `jenkins build JOB/PATH NUM` | Formatted build summary |
| `jenkins console JOB/PATH NUM [lines]` | Console output (last N lines) |
| `jenkins trigger JOB/PATH [K=V ...]` | Trigger build |
| `jenkins params JOB/PATH NUM` | Build parameters |

### Job Path Format

Strip `/job/` from the URL:
- URL: `https://jenkins.devotools.com/job/RaD-Deployments/job/aws-eu-pro/job/metamalote/132/`
- Path: `RaD-Deployments/aws-eu-pro/metamalote`

### Seed Job — cloudops-job-seed

**IMPORTANT:** `cloudops-job-seed` auto-generates jobs from Groovy files in the `jenkinsfiles` repo. It uses `removedJobAction>DELETE` — jobs outside its glob patterns are **deleted on next seed run**. After any Jenkins restore/reinstall, manually created jobs are lost unless their Groovy files are covered by a seed glob.

**Current gaps** — these Groovy files exist in the repo but are NOT picked up by the seed:
- `jobs/job_ops_*.groovy` (tabula-rasa-automated, batrasio restart, etc.)
- `jobs/tabula-rasa-schedules/*.groovy` (Weekly-Schedules wrapper jobs)

**Long-term fix:** Add these patterns to `cloudops-job-seed` targets → jobs survive any restore automatically.

**2026-05-18 outage:** Victor restored Jenkins from April 16 EBS snapshot — all jobs created since March 21 are missing. Original live volume `vol-00c5d86abda17aba0` is still **detached and available** in AWS (eu-west-1). Best recovery: re-attach it (zero data loss). Best snapshot fallback: `snap-0e3c898a8eed17374` (May 18 03:17 UTC, 8h before outage). Current Jenkins running 2.541.1 with API broken (HTTP 500).

Full details + recovery steps + all snapshot IDs: `jenkins/cloudops-job-seed.md`

### Known Jobs

**`RaD-Deployments/aws-eu-pro/metamalote`** — Deploy metamalote on EU datanodes  
Playbook: `ansible/custom/ansible_collections/devoinc/malotev2/playbooks/metamalote.yml`  
Requires manual approval before execution.

**`deploy-users/deploy-users-devtools`** — Deploy user accounts on Devtools hosts (Nexus, Jenkins, GitLab runners)  
User list: `Devtools/environment/group_vars/all/env_vars.yml`

**`RaD-Deployments/datanode-trash-deletion-http`** — Master trash cleanup job  
Regional wrappers: `RaD-Deployments/aws-{ap,us,eu}-pro/Weekly-Schedules_Trash-Cleaner` and `gcp-eu-tef/Weekly-Schedules_Trash-Cleaner` (every Sunday 06:00 AM)

### Disk Space Management

**Symptom:** All jobs stuck "Waiting for next available executor" — Jenkins disables Built-In Node when disk < 1 GB.

```bash
# Check disk status via SSH
ssh 10.255.1.198 "df -h /var/lib/jenkins"

# Find largest job directories
ssh 10.255.1.198 "sudo bash -c 'cd /var/lib/jenkins/jobs && du -sh * 2>/dev/null | grep -E \"^[0-9]+G\" | sort -h | tail -15'"
```

**Fix — configure build retention (UI):**
1. Job → Configure → "Discard old builds" → "Max # of builds to keep": **10**

**Fix — update config.xml via API:**
```bash
source ~/.devo/credentials
curl -s -u "${JENKINS_USER}:${JENKINS_API_TOKEN}" \
  "${JENKINS_URL}/job/{path}/config.xml" > /tmp/job-config.xml
sed -i '' 's/<numToKeep>[0-9]*<\/numToKeep>/<numToKeep>10<\/numToKeep>/' /tmp/job-config.xml
CRUMB=$(curl -s -u "${JENKINS_USER}:${JENKINS_API_TOKEN}" \
  "${JENKINS_URL}/crumbIssuer/api/json" | jq -r '.crumb')
curl -X POST -H "Jenkins-Crumb: ${CRUMB}" -H "Content-Type: application/xml" \
  -u "${JENKINS_USER}:${JENKINS_API_TOKEN}" \
  --data-binary "@/tmp/job-config.xml" "${JENKINS_URL}/job/{path}/config.xml"
```

**Recommended retention policies:**

| Job Type | Retention |
|---|---|
| Deployment jobs | 10-20 builds |
| CI/CD pipelines | 30 builds |
| Cleanup jobs (trash-deletion) | **10 builds** (5 GB each!) |

**GOTCHA — Groovy pipeline overrides UI setting:**  
If a pipeline job uses `buildDiscarder(logRotator(numToKeepStr: 'N'))` in its `options {}` block, it **overwrites** whatever you set in the UI on every run. Check the Groovy script first — UI change alone won't stick.

**GOTCHA — UI setting won't prune existing builds retroactively:**  
Changing retention only takes effect on the *next* build run. To reclaim disk immediately, delete old builds via API:
```bash
source ~/.devo/credentials
CRUMB=$(curl -s -u "${JENKINS_USER}:${JENKINS_API_TOKEN}" "${JENKINS_URL}/crumbIssuer/api/json" | jq -r '.crumb')
for build in $(seq <first> <last>); do
  curl -s -o /dev/null -X POST -H "Jenkins-Crumb: ${CRUMB}" \
    -u "${JENKINS_USER}:${JENKINS_API_TOKEN}" \
    "${JENKINS_URL}/job/<JOB_PATH>/${build}/doDelete"
done
```

**GOTCHA — Node stays offline (cached disk reading) after cleanup:**  
Jenkins caches the disk reading that triggered the offline state. Even after freeing space, the node stays offline. Restart Jenkins to force a fresh disk check:
```bash
# Show command to user and wait for confirmation before running
ssh 10.255.1.198 "sudo systemctl restart jenkins"
# Jenkins takes ~2-3 min to fully start; watch:
until curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
  -u "${JENKINS_USER}:${JENKINS_API_TOKEN}" "${JENKINS_URL}/api/json" | grep -q 200; do sleep 15; done
echo "Jenkins is UP"
```

### GitLab Credentials (Token Expiry Warning)

Jenkins checks out from gitlab.com using `gitlab-com-access-token` (PAT — expires in 1 year).

**Permanent solutions:**
- SSH Deploy Keys (never expire, preferred)
- Deploy Tokens (never expire, HTTPS)

**Migration guide:** `~/.claude/skills/devo-devtool/jenkins/credential-migration-guide.md`

### Troubleshooting

**Invalid job path:** Use plain slashes `RaD-Deployments/aws-eu-pro/metamalote`, not `/job/` form

**Jenkins CLI not working:** CLI blocked by nginx proxy (HTTP 400) — use REST API helper functions only

**"Oops! A problem occurred" on login after restart:**  
Caused by a stale OAuth callback URL (`/securityRealm/finishLogin?code=...&state=...`) left open in the browser before the restart. The OAuth state token is invalidated on restart. Fix: close the tab, open `https://jenkins.devotools.com` in a fresh tab.

**Groovy pipeline job — duplicate DB credential rows causing failure:**  
If a Groovy pipeline queries credentials by domain name and gets multiple rows, use `LIMIT 1` in the SQL query — any active key is valid. Do not error on duplicates. Example fix:
```groovy
// WRONG — errors if domain has multiple active credential rows
-e "SELECT ... LIMIT 2;"
if (rows.size() > 1) { error("matched ${rows.size()} credential rows") }

// CORRECT — always take first active row
-e "SELECT ... LIMIT 1;"
def cols = queryResult.split('\t')
```

---

## GitLab CI/CD Pipelines

### Issue 1: Package Manager Mismatch (`apk` not found)

```yaml
before_script:
  # OLD — Alpine (fails on Debian images)
  - apk update && apk add git
  # NEW — Debian (works with public.ecr.aws/bitnami/node:22)
  - apt-get update && apt-get install -y git
```

### Issue 2: Authentication Failures

**Symptoms:** `remote: HTTP Basic: Access denied`, `fatal: Authentication failed`

**Fix:**

```bash
# 1. Create Project Access Token (Settings > Access Tokens)
#    Role: Maintainer (40), Scopes: api, read_repository, write_repository

# 2. Get bot username
curl --header "PRIVATE-TOKEN: ${YOUR_TOKEN}" \
  "https://gitlab.com/api/v4/users/${USER_ID}" | jq .username

# 3. Set CI/CD variables
curl --request POST \
  --header "PRIVATE-TOKEN: ${YOUR_TOKEN}" \
  --form "key=GITLAB_TOKEN" --form "value=${BOT_TOKEN}" --form "masked=true" \
  "https://gitlab.com/api/v4/projects/${PROJECT_ID}/variables"

curl --request POST \
  --header "PRIVATE-TOKEN: ${YOUR_TOKEN}" \
  --form "key=GITLAB_REPO_USER" --form "value=${BOT_USERNAME}" \
  "https://gitlab.com/api/v4/projects/${PROJECT_ID}/variables"
```

**.gitlab-ci.yml pattern:**
```yaml
before_script:
  - git config user.name "devo_automation"
  - git config user.email "devo_automation@devo.com"
  - git remote set-url origin "https://${GITLAB_REPO_USER}:${GITLAB_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git"
```

### Issue 3: Protected Branch Blocking Pushes

```bash
# Unprotect then re-protect with correct settings
curl --request DELETE \
  --header "PRIVATE-TOKEN: ${YOUR_TOKEN}" \
  "https://gitlab.com/api/v4/projects/${PROJECT_ID}/protected_branches/master"

curl --request POST \
  --header "PRIVATE-TOKEN: ${YOUR_TOKEN}" \
  --form "name=master" --form "push_access_level=40" --form "merge_access_level=30" \
  "https://gitlab.com/api/v4/projects/${PROJECT_ID}/protected_branches"
```

### Issue 4: Infinite Pipeline Loop

```yaml
publish_dry:
  rules:
    - if: $CI_COMMIT_MESSAGE =~ /^Release:/
      when: never  # Skip publish on release commits
    - if: $CI_COMMIT_BRANCH == "master"
      when: manual
```

Ensure `.release-it.json` uses matching format: `"commitMessage": "Release: ${version}"`

### Issue 5: MR Pipelines Not Running Jobs

Remove `pipeline-preview.yml` include and add explicit rules:
```yaml
build:
  rules:
    - if: '$CI'  # Always run in CI

test:jest:
  rules:
    - if: '$CI'
```

### Issue 6: Empty Release Pipeline

```yaml
# Add at top of .gitlab-ci.yml
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH
    - if: $CI_MERGE_REQUEST_IID
```

### Issue 7: Vault 522 Timeouts (gitlab-support backend revoked)

**Symptoms:** `dial tcp: lookup openbao-support.strike48.com: no such host` or 522 errors

**Fix — remove Vault blocks, use CI/CD variables instead:**
```yaml
# BEFORE (broken)
job_name:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://openbao-support.strike48.com
  secrets:
    GITLAB_TOKEN:
      vault: gitlab-support/...

# AFTER (working)
job_name:
  # Migrated from revoked gitlab-support Vault backend to GitLab CI/CD variables
  script:
    - echo "Token from CI/CD variable: $GITLAB_TOKEN"
```

```bash
# Add token as CI/CD variable
curl --request POST --header "PRIVATE-TOKEN: ${YOUR_TOKEN}" \
  --form "key=GITLAB_TOKEN" --form "value=${TOKEN_VALUE}" \
  --form "protected=true" --form "masked=true" \
  "https://gitlab.com/api/v4/projects/${PROJECT_ID}/variables"
```

### Issue 8: Reverse Migration — CI/CD Variables back to OpenBao

**When:** Centralizing secrets management across multiple projects to https://openbao-prod.devo.com/

```yaml
job_name:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://openbao-prod.devo.com
  secrets:
    GITLAB_TOKEN:
      vault: gitlab-prod/promotion/data/gitlab@gitlab-prod
      field: token
    ARGO_TOKEN:
      vault: gitlab-prod/deployment/data/argo@gitlab-prod
      field: token
```

**Token mapping:**

| Variable | Vault Path | Usage |
|---|---|---|
| GITLAB_TOKEN | `gitlab-prod/promotion/data/gitlab` | MR creation, pushing commits |
| ARGO_TOKEN | `gitlab-prod/deployment/data/argo` | Argo CD operations |
| NEO_TRIGGER_TOKEN | `gitlab-prod/testing/data/neo` | NEO test automation |

**OpenBao production:** https://openbao-prod.devo.com — 3-replica HA, DevTools cluster (281139278838, eu-west-1), namespace `openbao-prod`

---

## Monitoring (Grafana / Prometheus / Alertmanager)

**Central Grafana:** https://grafana.observability.devo.com/ (observability cluster, `grafana-operator` namespace)  
**Per-cluster Grafana:** grafana-{eu,us,us3,apac}.devo.com (robusta namespace)  
**Prometheus/Alertmanager:** Per-cluster StatefulSets in `robusta` namespace

### Quick Health Check

```bash
# All clusters
for cluster in prod-eu prod-us prod-us3 prod-apac; do
  echo "=== $cluster ==="
  source ~/.zshrc && kube config use-context $cluster
  source ~/.zshrc && kube get pods -n robusta | grep -E "prometheus|alertmanager|grafana"
done

# Central Grafana
source ~/.zshrc && kube config use-context observability
source ~/.zshrc && kube get pods -n grafana-operator
```

### Creating Alertmanager Silences

**Prerequisites:**
```bash
aws sso login --profile production-limited
aws eks update-kubeconfig --name prod-eu --region eu-west-1 --profile production-limited --alias prod-eu-limited
source ~/.zshrc && kube config use-context prod-eu-limited
```

**Create 7-day silence:**
```bash
START_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
END_TIME=$(date -u -v+7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '+7 days' +%Y-%m-%dT%H:%M:%SZ)

source ~/.zshrc && kube exec -n robusta alertmanager-robusta-kube-prometheus-st-alertmanager-0 -c alertmanager -- sh -c "
wget -S -O- --post-data='{
  \"comment\": \"CHG-XXXXX - Reason\",
  \"createdBy\": \"your.name@devo.com\",
  \"endsAt\": \"${END_TIME}\",
  \"matchers\": [
    {\"isEqual\": true, \"isRegex\": false, \"name\": \"alertname\", \"value\": \"ALERT_NAME\"},
    {\"isEqual\": true, \"isRegex\": true, \"name\": \"LABEL\", \"value\": \".*pattern.*\"}
  ],
  \"startsAt\": \"${START_TIME}\"
}' --header='Content-Type: application/json' http://localhost:9093/api/v2/silences 2>&1
"
```

**Multi-cluster silence:**
```bash
for cluster in prod-eu prod-us prod-us3 prod-apac; do
  source ~/.zshrc && kube config use-context ${cluster}-limited
  source ~/.zshrc && kube exec -n robusta alertmanager-robusta-kube-prometheus-st-alertmanager-0 -c alertmanager -- sh -c "
  wget -S -O- --post-data='{\"comment\": \"CHG-XXXXX\", \"createdBy\": \"${USER}@devo.com\",
    \"endsAt\": \"${END_TIME}\", \"matchers\": [
      {\"isEqual\": true, \"isRegex\": false, \"name\": \"alertname\", \"value\": \"ALERT_NAME\"},
      {\"isEqual\": true, \"isRegex\": true, \"name\": \"LABEL\", \"value\": \".*pattern.*\"}
    ], \"startsAt\": \"${START_TIME}\"}' \
  --header='Content-Type: application/json' http://localhost:9093/api/v2/silences 2>&1" | grep silenceID
done
```

**List / delete silences:**
```bash
source ~/.zshrc && kube exec -n robusta alertmanager-robusta-kube-prometheus-st-alertmanager-0 -c alertmanager -- \
  wget -qO- 'http://localhost:9093/api/v2/silences' | python3 -m json.tool

source ~/.zshrc && kube exec -n robusta alertmanager-robusta-kube-prometheus-st-alertmanager-0 -c alertmanager -- \
  wget -qO- --method=DELETE 'http://localhost:9093/api/v2/silence/<SILENCE_ID>'
```

### Silence Not Working — Diagnosis

**1. Check if alert was "in flight" (sent before silence was created):**
```bash
# Convert Jira alert URL timestamp (milliseconds) to UTC
python3 -c "import datetime; ts=1776701796105/1000; print(datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc))"
# If alert timestamp < silence creation → normal, wait 10-15 min
```

**2. Check label name is correct** — use `datamalote`, not `datanode` or `instance`

**3. Check if alert is from a different cluster** — look for `env=prometheus-metrics-us` in labels

**4. Check if alert is from external Grafana** — URL contains `.devo.cloud` domain; create silence in that UI

**5. Common alert name variants to silence (all at once):**
```bash
ALERT_VARIANTS=(
  "malote_droppeddatanode-prometheus-metrics-datanode-malote"
  "metamalote_droppeddatanode-prometheus-metrics-datanode-malote"
  "malote_droppeddatanode-prometheus-metrics-us-datanode-malote"
  "metamalote_droppeddatanode-prometheus-metrics-us-datanode-malote"
)
```

### Dropped Datanode `datamalote=unknown` Alert — Persistent (Root Cause Fix)

**Symptoms:** Alert fires every ~15 min even after silences/restarts. Metric: `chasys_droppeddatanodesdetector_listdatamalotes{datamalote="unknown"} 1.0` from `172.17.200.6:18888`

**Root cause:** Decommissioned customer entries remain `enabled=1` in the `installation` table in RDS. All 10 EU metamalote-general hosts read this DB and keep trying to connect to dead IPs.

**What does NOT fix this:** conf file edits, Ansible redeployment, Alertmanager silences, restarting metamalotes (temporary only)

**Permanent fix:**
```bash
# Connect to shared RDS
source ~/.zshrc && sql eu_pro -e "SELECT type, COUNT(*), SUM(IF(enabled=1,1,0)) as enabled FROM installation WHERE name LIKE '%<customer>%' GROUP BY type;"
source ~/.zshrc && sql eu_pro -e "UPDATE installation SET enabled = 0 WHERE name LIKE '%<customer>%';"

# Restart all EU general metamalotes
for i in 1 2 3 4 5 6 7 8 9 10; do
  ssh metamalote-${i}-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && systemctl is-active metamalote"
done
```

**Chasys host:** `monitoring-1-infra-cloud-noc-aws-eu-west-1` (172.17.200.6)  
Config: `/etc/logtrust/chasys/config/chasys.parameters`  
Chasco: `/etc/logtrust/chasys/chascos/droppedDatanodesDetector.groovy`

### Prometheus Operations

```bash
# Check pod
source ~/.zshrc && kube get pods -n robusta | grep prometheus
source ~/.zshrc && kube logs -n robusta prometheus-robusta-kube-prometheus-st-prometheus-0 -c prometheus --tail=100

# Check alert rules
source ~/.zshrc && kube get configmap prometheus-robusta-kube-prometheus-st-prometheus-rulefiles-0 -n robusta -o yaml | grep -A 20 "alert: KubePodCrashLooping"

# Check storage
source ~/.zshrc && kube exec -n robusta prometheus-robusta-kube-prometheus-st-prometheus-0 -c prometheus -- df -h /prometheus

# Port-forward to Prometheus UI
source ~/.zshrc && kube port-forward -n robusta prometheus-robusta-kube-prometheus-st-prometheus-0 9090:9090
# Access: http://localhost:9090/alerts

# Restart (delete pod — StatefulSet recreates it)
source ~/.zshrc && kube delete pod prometheus-robusta-kube-prometheus-st-prometheus-0 -n robusta
```

**Alert rule summary:** 140 rules — 39 CRITICAL, 94 WARNING, 5 INFO. Categories: Kubernetes infra (57), Prometheus self-monitoring (29), Node/System (26), etcd (15), Alertmanager (8), Other (5).

### Grafana Operations

```bash
# Central Grafana
source ~/.zshrc && kube config use-context observability
source ~/.zshrc && kube get all,ingress -n grafana-operator
source ~/.zshrc && kube rollout restart deployment/grafana-deployment -n grafana-operator

# Robusta Grafana (per cluster)
source ~/.zshrc && kube config use-context prod-eu
source ~/.zshrc && kube get pods -n robusta | grep grafana
```

**Access:** Google SSO (@devo.com / @internal.devo.com) — role mapping: `grafana_admin@devo.com` → Admin

---

---

## Ansible — Infrastructure Management

All Ansible commands run from `~/Documents/Repository/` (automation repo). Always `source ~/.zshrc` first.

### Inventory Hosts Files — Key Paths

| Environment | Hosts File |
|---|---|
| EU Pro | `ansible/environments/aws/eu/pro/hosts` |
| US Pro | `ansible/environments/aws/us/pro/hosts` |
| US3 Pro | `ansible/environments/aws/us/pro3/hosts` |
| APAC Pro | `ansible/environments/aws/ap/pro/hosts` |
| CA Pro | `ansible/environments/aws/ca/pro/hosts` |
| GCP TEF | `ansible/environments/gcp/eu/tef/hosts` |
| Santander EU | `ansible/environments/aws/eu/santander/hosts` |
| NCSC Bahrain | `ansible/environments/aws/me/ncscbh/hosts` |

### Common Host Groups

| Group | Matches |
|---|---|
| `datanode-shared` | All shared datanodes |
| `datanode-panda` | Panda dedicated datanodes |
| `datanode-caixabank` | CaixaBank datanodes |
| `datanode-talion` | Talion datanodes |
| `datanode-self` | Self (platform) datanodes |
| `datanode-imagenio` | GCP Imagenio datanodes |
| `metamalote-general` | All general metamalotes |
| `batrasio-shared` | Shared batrasios |

### Basic Command Structure

```bash
ansible <host-or-group> -f <forks> -i <hosts-file> -m shell -b -a '<command>' 2>/dev/null
# -f 36    → parallel forks (use 36 for large groups)
# -b       → become (sudo)
# --limit  → restrict to specific nodes
```

---

### Scanning Datanode Disk — Domain Size Analysis

**Fastest pattern — scan specific domain across all trunks/buckets on ALL shared DNs:**
```bash
# All panda aggr files for required:* casparables (Jul 2024)
source ~/.zshrc && ansible datanode-shared -f 36 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
  'du -sch /var/logt/tr?/b0?/t02/2024/07/*/*@pandasecurity/logtrust/aggr/required* 2>/dev/null | grep total' 2>/dev/null

# Specific customer across all years
source ~/.zshrc && ansible datanode-shared -f 36 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
  'du -sch /var/logt/tr?/b0?/t02/2021/*/*/catawiki /var/logt/tr?/b0?/t02/2022/*/*/catawiki /var/logt/tr?/b0?/t02/2023/*/*/catawiki /var/logt/tr?/b0?/t02/2024/0?/*/catawiki 2>/dev/null | grep -v "^0" | grep total' 2>/dev/null
```

**Domain size breakdown by customer (single DN, one trunk/bucket):**
```bash
# From Ansible — size per domain, sorted largest first
source ~/.zshrc && ansible datanode-7-pro-cloud-shared-aws-eu-west-1 -f 36 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
  'du -sch /var/logt/tr0/b00/t02/2024/07/*/* 2>/dev/null | awk '\''$1 ~ /[0-9\.]+[MG]/ {n=split($2, a, "/"); print $1, a[n]}'\'' | awk '\''{size=substr($1, 1, length($1)-1); unit=substr($1, length($1)); if(unit=="G") size*=1024; arr[$2]+=size} END {for (i in arr) printf "%.2fG\t%s\n", arr[i]/1024, i}'\'' | sort -k1 -rg' 2>/dev/null

# All shared DNs, months 1-6 of 2024
source ~/.zshrc && ansible datanode-shared -f 36 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
  'for mn in {1..6}; do m=$(printf "2024/%02d" "$mn"); du -sch /var/logt/tr0/b0?/t02/$m/*/* 2>/dev/null | awk -v month="$m" '\''$1~/[0-9\.]+[MG]/{n=split($2,a,"/");arr[a[n]]+=$1;mon[a[n]]=month} END{for(d in arr) if(d!="total"){size=arr[d]; sub(/G$/,"",size); if(size~/\./) size*=1; printf "%.2fG\t%s\t%s\n", size, d, mon[d]}}'\'' | sort -k1 -rg; done | column -t' 2>/dev/null
```

**Disk usage per volume (df):**
```bash
# Check all trunk volumes
source ~/.zshrc && ansible datanode-shared -f 36 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
  'df -hPT /var/logt/tr?/b0?/t02 | grep tr' 2>/dev/null

# GCP imagenio (uses ebs paths, not tr)
source ~/.zshrc && ansible datanode-imagenio -f 36 -i ansible/environments/gcp/eu/tef/hosts -m shell -b -a \
  'df -hPT /var/logt/t00?' 2>/dev/null
```

**Count/find specific files (faster than find for known paths):**
```bash
# Fast: use du with exact glob pattern instead of find
du -sch /var/logt/tr?/b0?/t02/2024/07/*/*@pandasecurity/logtrust/aggr/required_3a*/g300000/_.alog

# If you must use find — target a specific date range, not all of /var/logt
find /var/logt -path '*@pandasecurity*/logtrust/aggr/required*' -name '*.alog' \
  -path '*/2024/07/*' 2>/dev/null | wc -l
```

---

### Service Management

```bash
# Check all services on datanodes
source ~/.zshrc && ansible datanode-shared -f 36 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
  'systemctl list-units | grep -iE "(alcohol|batrasio|devo-monitor|devo-relay|licor|malote|netdata|mason|metamalote)"' 2>/dev/null

# Restart metamalote on a customer cluster
source ~/.zshrc && ansible datanode-caixabank -f 36 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
  'systemctl restart metamalote.service' 2>/dev/null

# Restart metamalote on APAC all DNs + metamalotes
source ~/.zshrc && ansible -b -f 35 -i ansible/environments/aws/ap/pro/hosts -m shell -a \
  'systemctl restart metamalote.service' metamalote,datanode 2>/dev/null

# Check mason-agent (lookup troubleshooting → /devo-tools)
source ~/.zshrc && ansible datanode-shared -f 36 -i ansible/environments/aws/ap/pro/hosts -m shell -b -a \
  'systemctl status mason-agent' 2>/dev/null

# Restart mason-agent on CA
source ~/.zshrc && ansible metamalote-general -f 36 -i ansible/environments/aws/ca/pro/hosts -m shell -b -a \
  'systemctl restart mason-agent.service' 2>/dev/null
```

---

### GC Log Analysis (Metamalote / Malote)

```bash
# Full GC pause history on equifax/optivmdr metamalotes
source ~/.zshrc && ansible datanode-equifax -f 36 -i ansible/environments/aws/us/pro/hosts -m shell -b -a \
  'tail -n 1000 /var/log/metamalote/metamalote.gc.log | grep Full | grep -v "Metadata GC" | awk -F "]" '\''{ print $1" "$NF }'\'' | cut -c2- | head -n 8 | awk '\''{ print $1" "$(NF-1)" "$NF }'\'' | awk -F"ms" '\''{ print $1" "$2 }'\'' | awk '\''{ $1=int($1/1000) ;}{ print; }'\'' | while read -r seconds changemem pauseseconds; do printf "%s %s %s\n" "$(date -d @${seconds} --rfc-3339=seconds)" "${changemem}" "${pauseseconds}"; done' 2>/dev/null

# Quick GC tail (any node directly)
ssh <node> "sudo tail /var/log/metamalote/metamalote.gc.log"
ssh <node> "sudo tail /var/log/malote/malote?.gc.log"

# Force GC (run as root on node)
jcmd 0 GC.run
```

---

### Adolfo — Datanode Management

**Enable / Disable / Readonly:**
```bash
# Enable
adolfo datanode enable --env eu_pro --dnname datanode-2-pro-cloud-shared-aws-eu-west-1 --exec
adolfo datanode enable --env usa_pro --dnname datanode-20-pro-cloud-shared-aws-us-east-1 --exec
adolfo datanode enable --env ap_pro --dnname datanode-6-pro-cloud-shared-aws-ap-southeast-1 --exec
adolfo datanode enable --env us3_pro --dnname datanode-2-pro3-cloud-trustwave-aws-us-east-2 --exec
adolfo datanode enable --env gcp_tef --dnname datanode-imagenio-4-pro-cloud-tef-gcp-europe-west1 --exec
adolfo datanode enable --env ca_pro --dnname datanode-9-pro-cloud-manulife-aws-ca-central-1 --exec

# Readonly (removes from write rotation, keeps data readable)
adolfo datanode readonly --env eu_pro --dnname datanode-2-pro-cloud-shared-aws-eu-west-1 --exec
adolfo datanode readonly --env usa_pro --dnname datanode-20-pro-cloud-shared-aws-us-east-1 --exec

# List status
adolfo datanode list --env eu_pro --dnname datanode-2-pro-cloud-shared-aws-eu-west-1 --exec | grep -E '(ENABLED|DISABLED|READONLY|INCOMPLETE)'
for dn in $(seq 1 10); do adolfo datanode list --env eu_pro --dnname="datanode-${dn}-pro-cloud-shared-aws-eu-west-1" | grep -E '(ENABLED|DISABLED|READONLY|INCOMPLETE)'; done

# Batch readonly (e.g. CaixaBank even-numbered nodes)
for a in $(seq 28 2 38); do adolfo datanode readonly --env eu_pro --dnname datanode-$a-pro-cloud-caixa-ng-ibm-eu-de-2 --exec; done
```

**Affinity — which datanodes a domain is on:**
```bash
adolfo affinity show -e eu_pro --domains admin@signalit --trunks
adolfo affinity show -e usa_pro --domains gitlab --trunks
adolfo affinity show -e ap_pro --domains ascendtravel@truedigitalgroup --trunks
adolfo affinity show -e gcp_tef_pro --domains telefonicasistemas --trunks
adolfo affinity show -e santander_eu --domains cert_gtb_bam --trunks

# Full affinity history (all domains matching pattern)
adolfo affinity show -e eu_pro -d panda -a   # -a = all history
```

---

### trash-amnesia Management

trash-amnesia is the soft-delete staging area on datanodes — files move here before permanent deletion.

**Fix permission issues (malote denied errors):**
```bash
# On datanode directly (tr0-tr7, b00-b01)
for a in $(seq 0 7); do chown logtrust:logtrust -R /var/logt/tr$a/b0?/trash-amnesia/*; done
for a in $(seq 0 7); do chmod 755 -R /var/logt/tr$a/b0?/trash-amnesia/*; done

# GCP (ebs paths)
ansible datanode-imagenio -f 36 -i ansible/environments/gcp/eu/tef/hosts -m shell -b -a \
  'for i in $(seq 0 7); do for j in $(seq 0 1); do chmod 755 /var/logt/ebs${i}/b0${j}/trash-amnesia; done; done' 2>/dev/null
```

**Trash cleanup playbook:**
```bash
ansible-playbook -f40 -v -i ansible/environments/aws/ap/pro/hosts \
  -e "host=metamalote-1-pro-cloud-general-aws-ap-southeast-1" \
  -e "cleanup_strategy=trash-amnesia" \
  -e "cleanup_days=14" \
  ansible/playbooks/datanode-trash-cleanup.yml 2>/dev/null
```

---

### Rsync — Data Movement

```bash
# Sync between trunks on same node
for i in $(seq 0 7); do for j in $(seq 0 1); do \
  rsync -a -rvvzpoh --relative --rsync-path="sudo rsync" --progress -P \
  /var/logt/tr${i}/b0${j}/t02/trash-amnesia-archive-330d/* \
  /var/logt/tr${i}/b0${j}/t02/trash-amnesia-archive-330d/; done; done

# Sync specific date to backup
rsync -a -rvvzpoh --relative --rsync-path="sudo rsync" --progress -P \
  /var/logt/tr1/b00/t02/2024/11/26 /var/logt/backup/tr1/b00/t00/2024/11/

# Pull missing folders from DN2 → DN1 via tar pipe
ssh datanode2 "sudo tar -C /var/logt/data/malote -cf - maxmind iputacion-lists" | \
  ssh datanode1 "sudo tar -C /var/logt/data/malote -xf -"
```

---

### File Distribution — SCP to Multiple Nodes

```bash
# Push script to multiple nodes
for dn in $(seq 1 2 59); do
  scp /Users/vikash.jaiswal/Documents/Scripts/test_malotes.sh \
    vikashjaiswal@datanode-${dn}-pro-cloud-caixa-ng-ibm-eu-de-3:/tmp/
done

# Then install via Ansible
source ~/.zshrc && ansible datanode-caixabank -f 36 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
  'mv /tmp/test_malotes.sh /usr/local/bin/ && chmod +x /usr/local/bin/test_malotes.sh && chown logtrust:users /usr/local/bin/test_malotes.sh' 2>/dev/null
```

---

### User Management

```bash
# Add user to nodes
ansible batrasio -f 35 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
  'USER="firstname.lastname"; SSH_KEY="ssh-rsa AAAA..."; \
   useradd -m -d /home/${USER} -s /bin/bash ${USER}; \
   mkdir /home/${USER}/.ssh; echo "${SSH_KEY}" > /home/${USER}/.ssh/authorized_keys; \
   chown -R "${USER}":"${USER}" /home/${USER}/.ssh; chmod -R 700 /home/${USER}/.ssh; \
   usermod -aG sudo ${USER}; usermod -aG adm ${USER}; usermod -aG admin ${USER}' 2>/dev/null

# Re-enable user password validity
ansible datanode -f 36 -i ansible/environments/aws/us/pro/hosts -m shell -b -a \
  'chage -m 0 -M 99999 -I -1 -E -1 firstname.lastname' 2>/dev/null
```

---

### Ansible Playbooks

```bash
# Deploy resilience health-check agents (EU self datanodes)
ansible-playbook ansible/playbooks/deploy-datanode-resilience.yml \
  -i ansible/environments/aws/eu/pro/hosts \
  -e target_hosts=datanode-self 2>/dev/null | tee /tmp/deployment-eu-self-$(date +%Y%m%d-%H%M%S).log

# Datanode facts check (dry-run)
ansible-playbook ansible/playbooks/datanode.yml \
  -i ansible/environments/aws/eu/santander/hosts \
  --limit "datanode1-santander-cloud-shared-aws-eu-west-1,datanode2-santander-cloud-shared-aws-eu-west-1" \
  --tags "role::datanode:facts" --check --diff

# SSM + CloudWatch agent deploy
ansible-playbook -f40 -v -i ansible/environments/aws/me/ncscbh/hosts \
  -e host=datanode-self ansible/playbooks/ssm-and-cloudwatch-agent-deploy.yaml
```

---

### Malote / Metamalote Operations

```bash
# Run test_malotes.sh on all datanodes
source ~/.zshrc && ansible datanode-shared -f 36 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
  '/usr/local/bin/test_malotes.sh' 2>/dev/null

# Unlock metamalote sync lock file (if stuck)
ssh <node> "sudo rm -rf /var/run/lock/metamalote_sync.sh.lock"
ssh <node> "sudo /usr/local/bin/datanode-metamalote_sync.sh"

# Reindex old data range (on datanode directly)
/usr/local/bin/reindex_old_data_range.sh -s 2024-12-01 -e 2024-12-10 \
  -t old -r /var/logt/ebs{0..7}/b0{0..1} -d telefonicasistemas -th 8 -ri true

# Pull jstack from malote processes
systemctl status malote@i?.service | grep "Main PID" | awk '{print $3}' > /tmp/output.txt
for x in $(cat /tmp/output.txt); do jstack $x > /tmp/malote${x}$(date -u +%FT%TZ).jstack; done
chmod 777 /tmp/*.jstack
```

---

### Batrasio / Certificate Checks

```bash
# Validate certificate chain
openssl verify -verbose \
  -CAfile /etc/logtrust/batrasio/keys/collector-54ad5.devo.io.root.crt \
  -untrusted /etc/logtrust/batrasio/keys/collector-54ad5.devo.io.crt \
  /etc/logtrust/batrasio/keys/collector-54ad5.devo.io.intermediate.crt

# Check cert expiry
openssl x509 -noout -text -in /etc/logtrust/batrasio/keys/collector-54ad5.devo.io.crt

# Check all batrasio targets responding (port 1514)
curl --silent http://localhost:3000/healthcheck | jq '.[0].targets' | \
  tr -d '",' | awk 'NR>2 {print last} {last=$1}' | \
  xargs -P 8 -r -I {} timeout 4 nc -w 3 -vz {} 1514 2>&1
# IBM Cloud uses port 3030 instead of 3000

# Check cert for all batrasios via Ansible
source ~/.zshrc && ansible batrasio -f 40 -i ansible/environments/aws/eu/pro/hosts -m shell -b -a \
  'echo | openssl s_client -showcerts -connect "$(ip route get 1 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | tail-1)":443 2>/dev/null | openssl x509 -noout -subject -issuer -enddate' 2>/dev/null
```

---

## Related Skills

- **`/devo-infra`** - Ansible deployments and Kubernetes cluster access
- **`/devo-tools`** - Platform architecture (Mason, Lomana, Asilo) + **all lookup troubleshooting** (missing data, udlu, blank grid)
- **`/devo-alert`** - Devo Alert management (Flow, Pilot, Cockpit)
- **`/devo-jira`** - Jira issue tracking
