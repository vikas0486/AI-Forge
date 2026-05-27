# Jenkins — Job Recovery, EBS Volumes & Snapshot History

## AWS Access — Priority Order

**Primary (always try first — opens browser SSO):**
```bash
aws sso login --profile devotools-limited
```

**Secondary (validate active session):**
```bash
aws sts get-caller-identity --profile devotools-limited
```

**All Jenkins AWS commands:** `--profile devotools-limited --region eu-west-1`
Jenkins is in account `281139278838` (devotools) — NOT `production-limited` (that's the K8s/Vault account).

---

## AWS — EBS Volumes & Snapshots

**Jenkins server:** `i-00544c45d9146781f` (10.255.1.198), account `281139278838` (devotools), eu-west-1

### Current Attached Volume (as of 2026-05-18)

| Device | Volume ID | Mount | Size | Created | Source Snapshot |
|---|---|---|---|---|---|
| `/dev/sdg` (nvme1n1) | `vol-073b4859aa51379e1` | `/var/lib/jenkins` | 600 GB | 2026-05-18 13:48 | `snap-097fb13c80727f6fd` (Apr 16) |

### Original Live Volume (DETACHED — still available, zero data loss)

| Volume ID | State | Size | Note |
|---|---|---|---|
| `vol-00c5d86abda17aba0` | **available** (detached) | 600 GB | All data up to Jenkins stop at 11:13 UTC May 18 — **best recovery option** |

### All Weekly Auto-Snapshots of the Live Volume (taken Sundays ~03:15 UTC)

All labeled `jenkins-restored-13-april-2026` — misleading name, does NOT mean old data.
The description was never updated after Victor's April 16 restore. Each snapshot contains
that week's actual live data.

| Snapshot ID | Date (UTC) | Content | Use |
|---|---|---|---|
| `snap-0e3c898a8eed17374` | **2026-05-18 03:17** | Live data — 8h before outage, all recent jobs intact, Jenkins 2.492.x correct plugins | ✅ **Best snapshot option** |
| `snap-0462ae6f71aa2ea8d` | 2026-05-11 03:15 | Live data — 1 week earlier | Good fallback |
| `snap-0fa184c4983b6bd17` | 2026-05-04 03:15 | Live data — 2 weeks earlier | Good fallback |
| `snap-0441fa00bf52c86cd` | 2026-04-27 03:15 | Live data | |
| `snap-07ae82b31b77cdea6` | 2026-04-20 03:17 | Live data | |
| `snap-097fb13c80727f6fd` | 2026-04-16 10:58 | Manual — "jenkins-working-16-april-2026-clean" | ⚠️ **Running now** — missing all jobs created after March 21 |
| `snap-0382e7e23ab924d62` | 2026-04-16 08:25 | Manual — "antes de restaurar" (before April 16 restore) | Pre-restore backup |

### Why Victor Picked the Wrong Snapshot (2026-05-18)

Victor saw the weekly snapshots all labeled `jenkins-restored-13-april-2026` and thought
they were old data. He trusted the `jenkins-working-16-april-2026-clean` label instead.
In reality, all 5 weekly snaps (Apr 20 → May 18) were snapshotting the **live volume** —
they had current data. The May 18 03:17 snap has everything. Victor picked the wrong one.

---

## 2026-05-18 Outage — Full Timeline

| Time (UTC) | Event |
|---|---|
| 03:17 | ✅ Auto weekly snapshot `snap-0e3c898a8eed17374` taken — last clean state |
| 09:39 | Jenkins auto-checks for plugin updates |
| 11:13 | Victor stops Jenkins |
| 11:20–16:03 | **5+ crash loops** — same error each time: `credentials-binding` → `git-client` → `git` → `gitlab-oauth` all fail to load; `config.xml` unreadable (`GitLabSecurityRealm` CannotResolveClassException) |
| 13:48 | Victor creates new volume `vol-073b4859aa51379e1` from **April 16 snapshot** (wrong choice — missing months of jobs) |
| 14:53 | New volume attached — original live volume `vol-00c5d86abda17aba0` detached |
| 15:07 | Victor creates `backup-before-upgrade-20260518-150710/` — configs only, no jobs, no plugins (useless for job recovery) |
| 15:50–15:55 | Victor upgrades plugins via Plugin Manager: git, git-client, credentials-binding, asm-api, jakarta-mail-api — still crashing |
| 16:03–16:16 | Continues crash loop — same plugin failures |
| 16:17 | Victor renames `.jpi` → `.hpi` for credentials-binding, git-client, gitlab-oauth; upgrades Jenkins WAR to **2.541.1** |
| 16:18 | Jenkins finally boots in **degraded state** — UI works, REST API returns HTTP 500 |

### Root Cause of Crash Loop

`asm-api` version `9.10-211` (built for Jenkins 2.492.3) failed compatibility check under 2.541.1.
This caused `credentials-binding` to fail → cascaded to `git-client` → `git` → `gitlab-oauth` →
`config.xml` unreadable → `HudsonFailedToLoad`. Victor eventually bypassed by renaming plugins
and upgrading the WAR — Jenkins limped into degraded boot.

### Current Jenkins State (as of 2026-05-19)

| Item | State |
|---|---|
| Jenkins version | 2.541.1 (WAR upgraded by Victor on May 18) |
| Volume | `vol-073b4859aa51379e1` from Apr 16 snapshot — missing recent jobs |
| UI | ✅ Working |
| REST API (`/api/json`) | ❌ HTTP 500 |
| `jenkins` CLI wrapper | ❌ Not working (uses API) |
| `lockable-resources` plugin | ⚠️ `.hpi` downloaded to `/var/lib/jenkins/plugins/` — needs restart to load |
| `ws-cleanup` plugin | ⚠️ `.hpi` downloaded to `/var/lib/jenkins/plugins/` — needs restart to load |
| Pipeline jobs | ⚠️ Fail on `lock` and `cleanWs` steps until restart loads the two plugins |

### Missing Jobs (present in live volume, absent in current running Jenkins)

- `RaD-Deployments/tabula-rasa-automated` (master pipeline)
- `RaD-Deployments/aws-ap-pro/Weekly-Schedules` (tabula-rasa/rebalance wrappers)
- `RaD-Deployments/infra-deployment/offboarding-domain` (offboarding wrapper)
- All manually created jobs not covered by a seed glob, created after March 21

---

## Recovery Plan

### Option 1 — Re-attach Original Live Volume (BEST — zero data loss)

The original volume `vol-00c5d86abda17aba0` is detached and available in eu-west-1a.
Has all data up to 11:13 UTC May 18. Also restores Jenkins 2.492.x + correct plugin versions.

```
⚠️ Requires explicit confirmation — involves Jenkins restart + volume swap
1. Stop Jenkins:        sudo systemctl stop jenkins
2. Detach current vol:  aws ec2 detach-volume --volume-id vol-073b4859aa51379e1 --region eu-west-1 --profile devotools-limited
3. Attach original vol: aws ec2 attach-volume --volume-id vol-00c5d86abda17aba0 --instance-id i-00544c45d9146781f --device /dev/sdg --region eu-west-1 --profile devotools-limited
4. Start Jenkins:       sudo systemctl start jenkins
```

### Option 2 — Restore from May 18 03:17 Snapshot (8h data gap, no job loss)

```bash
# Create new volume from snapshot (eu-west-1a to match instance AZ)
aws ec2 create-volume \
  --snapshot-id snap-0e3c898a8eed17374 \
  --availability-zone eu-west-1a \
  --volume-type gp3 --size 600 \
  --region eu-west-1 --profile devotools-limited
# Then same stop/detach/attach/start as Option 1
```

### Option 3 — Recreate Jobs from Groovy (no AWS, build history lost)

Add missing glob patterns to `cloudops-job-seed` and trigger it. Jobs recreated, history gone.

---

## cloudops-job-seed — Job Auto-Generation

`cloudops-job-seed` generates jobs from Groovy files in `jenkinsfiles` repo
(`git@gitlab.devotools.com:devops/jenkins/jenkinsfiles.git`, branch `master`).

**Critical:** `removedJobAction>DELETE` — jobs outside glob patterns are deleted on next seed run.

### Current Glob Patterns

```
jobs/job_deploy_matasmafias_aws_*.groovy
jobs/job_deploy_matasmafias_gcp_*.groovy
jobs/job_deploy_matasmafias_vdc_*.groovy
jobs/job_deploy_users*
```

### NOT Covered (add these to prevent future job loss)

```
jobs/job_ops_*.groovy              ← covers all ops jobs
jobs/tabula-rasa-schedules/*.groovy
```

**File to edit:** `/var/lib/jenkins/jobs/cloudops-job-seed/config.xml`
or Jenkins UI → cloudops-job-seed → Configure → Build → Job DSL → targets.

### Groovy Files Currently Outside Seed Coverage

| Groovy File | Job It Creates |
|---|---|
| `jobs/job_ops_tabula_rasa_automated.groovy` | `RaD-Deployments/tabula-rasa-automated` |
| `jobs/tabula-rasa-schedules/ap_pro_rebalance_weekly.groovy` | APAC Weekly-Schedules rebalance |
| `jobs/tabula-rasa-schedules/ap_pro_tabularasa_biweekly.groovy` | APAC Weekly-Schedules tabularasa |
| `jobs/tabula-rasa-schedules/eu_pro_*.groovy` | EU wrappers |
| `jobs/tabula-rasa-schedules/us_pro_*.groovy` | US wrappers |
| `jobs/tabula-rasa-schedules/us3_pro_*.groovy` | US3 wrappers |
| `jobs/tabula-rasa-schedules/gcp_tef_*.groovy` | GCP-TEF wrappers |
| `jobs/job_ops_restart_batrasio_service.groovy` | `ops/ops-restart-batrasio-service` |
